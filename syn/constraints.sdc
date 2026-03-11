# ====================================================================
# SDC CONSTRAINTS FILE (constraints.sdc)
# FINAL TIMING FOR 90nm COMBINATIONAL LOGIC
# ====================================================================

# 1. Define the Master Clock (6.5 ns = ~153 MHz)
create_clock -name clk -period 6.5 [get_ports clk]

# 2. Clock Network Constraints
set_ideal_network [get_ports clk]

# 3. I/O Boundary Constraints (20% of 6.5ns)
set_input_delay  1.3 -clock clk [all_inputs]
set_output_delay 1.3 -clock clk [all_outputs]
