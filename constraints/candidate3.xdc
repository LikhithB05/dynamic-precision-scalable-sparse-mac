# ==============================================================================
# Port-Corrected Constraints for mac_sparse_ulp_precision_gated
# Target: xc7a200tfbg676-2 @ 12.000 MHz (83.333 ns)
# ==============================================================================

# Primary clock: 12 MHz
create_clock -period 83.333 -name clk [get_ports clk]

# Provisional operand input timing assumptions:
# Inputs A and B arrive between 0 ns and 5 ns after the reference edge.
set_input_delay -clock clk -max 5.000 [get_ports {A[*] B[*]}]
set_input_delay -clock clk -min 0.000 [get_ports {A[*] B[*]}]

# Output timing assumptions (corrected to match actual top-level ports):
# product[63:0], accumulator_out[64:0], carry_out, skip_flag
set_output_delay -clock clk -max 2.000 [get_ports {product[*] accumulator_out[*] carry_out skip_flag}]
set_output_delay -clock clk -min 0.000 [get_ports {product[*] accumulator_out[*] carry_out skip_flag}]
