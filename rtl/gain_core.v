`timescale 1ns / 1ps
// ============================================================
// Module      : gain_core
// Description : Fixed-point audio gain block with saturation
//               - Signed PCM input
//               - Fixed-point gain (Q format)
//               - Optional bypass
//
// Data format :
//   data_i     : signed PCM (DWIDTH bits)
//   data_gain  : signed fixed-point gain (Qx.FBITS)
//   data_o     : signed PCM (DWIDTH bits)
//
// Notes:
//   - Saturation is applied after scaling
//   - Bypass path skips multiplication
// ============================================================

module gain_core #(
    parameter integer DWIDTH = 16, // Audio data width
    parameter integer GWIDTH = 16, // Gain width
    parameter integer FBITS  = 12  // Fractional bits (Q format)
)(
    input  wire                     clk,
    input  wire                     rst_n,     // Active-low reset
    input  wire                     ce,        // Clock enable
    input  wire                     en,        // 1: gain enable, 0: bypass
    input  wire signed [DWIDTH-1:0] data_i,    // Audio input
    input  wire signed [GWIDTH-1:0] data_gain, // Gain value (fixed-point)
    output reg  signed [DWIDTH-1:0] data_o     // Audio output
);

    // ------------------------------------------------------------
    // Internal signals
    // ------------------------------------------------------------

    // Raw multiplication result (wider than input)
    wire signed [DWIDTH+GWIDTH-1:0] mult_raw;

    // Convergen rounding after raw multiplication
    wire signed [DWIDTH+GWIDTH-1:0] mult_rounded;
    
    // Scaled result after removing fractional bits
    wire signed [DWIDTH+GWIDTH-1-FBITS:0] mult_scaled;

    // Saturation limits for DWIDTH
    localparam signed [DWIDTH-1:0] MAX_VAL = {1'b0, {(DWIDTH-1){1'b1}}}; // +32767
    localparam signed [DWIDTH-1:0] MIN_VAL = {1'b1, {(DWIDTH-1){1'b0}}}; // -32768

    // ------------------------------------------------------------
    // Combinational logic
    // ------------------------------------------------------------

    // Signed multiplication
    assign mult_raw = data_i * data_gain;

    // (1 << (FBITS-1)) as representation of 0.5 in fixed-point data format
    assign mult_rounded = mult_raw + (1 << (FBITS-1));
    
    // Arithmetic right shift to restore scale
    assign mult_scaled = mult_rounded >>> FBITS;

    // ------------------------------------------------------------
    // Sequential logic
    // ------------------------------------------------------------

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_o <= 0;
        end else if (ce) begin
            if (!en) begin
                // Bypass mode
                data_o <= data_i;
            end else begin
                // Gain mode with saturation
                if (mult_scaled > MAX_VAL) begin
                    data_o <= MAX_VAL;
                end else if (mult_scaled < MIN_VAL) begin
                    data_o <= MIN_VAL;
                end else begin
                    data_o <= mult_scaled[DWIDTH-1:0];
                end
            end
        end
    end

endmodule
