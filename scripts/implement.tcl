# Run from a new build directory using Vivado 2026.1.
set root [file normalize [file join [file dirname [info script]] ..]]
set dest [file join [pwd] candidate3_implementation]
if {[file exists $dest]} {error "Choose a fresh build directory"}
file mkdir $dest
cd $dest
foreach name {mode_controller operand_formatter booth_encoder_r4 partial_product_generator csa wallace_tree_32} {
    read_verilog [file join $root rtl common ${name}.v]
}
read_verilog [file join $root rtl optimized mac_sparse_ulp_precision_gated.v]
read_xdc [file join $root constraints candidate3.xdc]
synth_design -top mac_sparse_ulp_precision_gated -part xc7a200tfbg676-2 -mode out_of_context -max_dsp 0
opt_design
place_design
route_design
report_utilization -file utilization.rpt
report_timing_summary -file timing_summary.rpt
report_power -file power_vectorless.rpt
