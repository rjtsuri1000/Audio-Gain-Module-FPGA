# ============================================================
# bd.tcl
#
# Minimal Block Design (Documentation-Oriented)
# Gain AXI-Stream module integrated with:
#   - Zynq UltraScale+ MPSoC
#   - AXI DMA (MM2S / S2MM)
#
# Purpose:
#   Illustrate system-level integration used for PYNQ validation.
#   Not intended to fully recreate board-specific presets.
# ============================================================

# ------------------------------------------------------------
# Create project if needed
# ------------------------------------------------------------
if {[llength [get_projects -quiet]] == 0} {
    create_project gain_bd ./gain_bd -part xck26-sfvc784-2LV-c
    set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]
}

# ------------------------------------------------------------
# Create block design
# ------------------------------------------------------------
create_bd_design "gain_bd"
current_bd_design gain_bd

# ------------------------------------------------------------
# Zynq PS (minimal, default preset)
# ------------------------------------------------------------
set ps [create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e ps]

# Enable AXI master for control & DMA
set_property -dict [list \
    CONFIG.PSU__USE__M_AXI_GP0 {1} \
    CONFIG.PSU__FPGA_PL0_ENABLE {1} \
] $ps

# ------------------------------------------------------------
# AXI DMA
# ------------------------------------------------------------
set dma [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma]
set_property -dict [list \
    CONFIG.c_include_sg {0} \
] $dma

# ------------------------------------------------------------
# Gain AXI wrapper (RTL module)
# ------------------------------------------------------------
set gain [create_bd_cell -type module -reference gain_axis_wrapper gain_0]

# ------------------------------------------------------------
# AXI Interconnect (control path)
# ------------------------------------------------------------
set axi_ic [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_ic]
set_property CONFIG.NUM_MI {2} $axi_ic

# ------------------------------------------------------------
# Reset block
# ------------------------------------------------------------
set rst [create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst]

# ------------------------------------------------------------
# Clock & reset wiring (simplified)
# ------------------------------------------------------------
connect_bd_net [get_bd_pins ps/pl_clk0] \
               [get_bd_pins dma/s_axi_lite_aclk] \
               [get_bd_pins gain/aclk] \
               [get_bd_pins axi_ic/ACLK] \
               [get_bd_pins rst/slowest_sync_clk]

connect_bd_net [get_bd_pins ps/pl_resetn0] \
               [get_bd_pins rst/ext_reset_in]

connect_bd_net [get_bd_pins rst/peripheral_aresetn] \
               [get_bd_pins dma/axi_resetn] \
               [get_bd_pins gain/aresetn] \
               [get_bd_pins axi_ic/ARESETN]

# ------------------------------------------------------------
# AXI-Lite control connections
# ------------------------------------------------------------
connect_bd_intf_net [get_bd_intf_pins ps/M_AXI_HPM0_FPD] \
                    [get_bd_intf_pins axi_ic/S00_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_ic/M00_AXI] \
                    [get_bd_intf_pins dma/S_AXI_LITE]

connect_bd_intf_net [get_bd_intf_pins axi_ic/M01_AXI] \
                    [get_bd_intf_pins gain/s_axi]

# ------------------------------------------------------------
# AXI-Stream data path
# ------------------------------------------------------------
connect_bd_intf_net [get_bd_intf_pins dma/M_AXIS_MM2S] \
                    [get_bd_intf_pins gain/s_axis]

connect_bd_intf_net [get_bd_intf_pins gain/m_axis] \
                    [get_bd_intf_pins dma/S_AXIS_S2MM]

# ------------------------------------------------------------
# Finalize
# ------------------------------------------------------------
validate_bd_design
save_bd_design

puts "INFO: Minimal Gain block design created (documentation-oriented)."
