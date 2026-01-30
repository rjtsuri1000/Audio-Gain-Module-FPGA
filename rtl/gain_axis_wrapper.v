`timescale 1ns / 1ps
// ============================================================================
// Module      : axis_gain_wrapper
// Description : AXI-Stream stereo gain wrapper with AXI-Lite control
//               - Stereo 16-bit PCM
//               - Per-channel fixed-point gain
//               - Single-stage skid buffer (deadlock-safe)
//
// AXI-Lite Register Map:
//   0x00 : Control   [0] Gain Enable
//   0x04 : Gain Left  (Q-format)
//   0x08 : Gain Right (Q-format)
//
// Notes:
//   - AXI-Lite is used only for configuration
//   - Data path is fully synchronous to AXI-Stream
//   - No internal FIFO; deterministic latency
// ============================================================================

module axis_gain_wrapper #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4,
    parameter integer AUDIO_WIDTH        = 16,
    parameter integer GAIN_FBITS         = 12
)(
    // Global clock & reset
    input  wire aclk,
    input  wire aresetn,

    // AXI4-Stream Slave (Input)
    input  wire [31:0] s_axis_tdata,
    input  wire        s_axis_tlast,
    input  wire        s_axis_tvalid,
    output wire        s_axis_tready,

    // AXI4-Stream Master (Output)
    output wire [31:0] m_axis_tdata,
    output wire        m_axis_tlast,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,

    // AXI4-Lite Slave (Control)
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                          s_axi_awvalid,
    output reg                           s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [3:0]                    s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output reg                           s_axi_wready,
    output reg  [1:0]                    s_axi_bresp,
    output reg                           s_axi_bvalid,
    input  wire                          s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                          s_axi_arvalid,
    output reg                           s_axi_arready,
    output reg  [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]                    s_axi_rresp,
    output reg                           s_axi_rvalid,
    input  wire                          s_axi_rready
);

    // =========================================================================
    // 1. AXI-LITE CONTROL REGISTERS
    // =========================================================================

    reg [31:0] reg_control;
    reg [31:0] reg_gain_l;
    reg [31:0] reg_gain_r;

    wire [1:0] addr_w = s_axi_awaddr[3:2];
    wire [1:0] addr_r = s_axi_araddr[3:2];

    // Write channel
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;

            reg_control <= 32'b0;
            reg_gain_l  <= 32'h0000_1000; // 1.0 (Q format)
            reg_gain_r  <= 32'h0000_1000;
        end else begin
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                case (addr_w)
                    2'h0: reg_control <= s_axi_wdata;
                    2'h1: reg_gain_l  <= s_axi_wdata;
                    2'h2: reg_gain_r  <= s_axi_wdata;
                    default: ;
                endcase
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            if (s_axi_awready && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // Read channel
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rdata   <= 32'b0;
            s_axi_rresp   <= 2'b00;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                case (addr_r)
                    2'h0: s_axi_rdata <= reg_control;
                    2'h1: s_axi_rdata <= reg_gain_l;
                    2'h2: s_axi_rdata <= reg_gain_r;
                    default: s_axi_rdata <= 32'b0;
                endcase
            end else begin
                s_axi_arready <= 1'b0;
                if (s_axi_rvalid && s_axi_rready)
                    s_axi_rvalid <= 1'b0;
            end
        end
    end

    // =========================================================================
    // 2. AXI-STREAM HANDSHAKE & PIPELINE
    // =========================================================================

    reg valid_d;
    reg last_d;

    // Single-stage skid buffer (deadlock-safe)
    wire stream_ready = m_axis_tready || !valid_d;

    assign s_axis_tready = stream_ready;
    assign m_axis_tvalid = valid_d;
    assign m_axis_tlast  = last_d;

    wire core_ce     = stream_ready;
    wire gain_enable = reg_control[0];

    // =========================================================================
    // 3. GAIN CORE INSTANTIATION (STEREO)
    // =========================================================================

    gain_core #(
        .DWIDTH(AUDIO_WIDTH),
        .GWIDTH(16),
        .FBITS (GAIN_FBITS)
    ) u_gain_l (
        .clk       (aclk),
        .rst_n     (aresetn),
        .ce        (core_ce),
        .en        (gain_enable),
        .data_i    (s_axis_tdata[15:0]),
        .data_gain (reg_gain_l[15:0]),
        .data_o    (m_axis_tdata[15:0])
    );

    gain_core #(
        .DWIDTH(AUDIO_WIDTH),
        .GWIDTH(16),
        .FBITS (GAIN_FBITS)
    ) u_gain_r (
        .clk       (aclk),
        .rst_n     (aresetn),
        .ce        (core_ce),
        .en        (gain_enable),
        .data_i    (s_axis_tdata[31:16]),
        .data_gain (reg_gain_r[15:0]),
        .data_o    (m_axis_tdata[31:16])
    );

    // =========================================================================
    // 4. PIPELINE REGISTERS
    // =========================================================================

    always @(posedge aclk) begin
        if (!aresetn) begin
            valid_d <= 1'b0;
            last_d  <= 1'b0;
        end else if (stream_ready) begin
            valid_d <= s_axis_tvalid;
            last_d  <= s_axis_tlast;
        end
    end

endmodule
