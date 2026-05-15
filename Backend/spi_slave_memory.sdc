#####################################################################
#
# Created by Genus(TM) Synthesis Solution 21.14-s082_1 on Tue May 05 15:32:23 IST 2026
#
#####################################################################

set sdc_version 2.0

set_units -capacitance 1000fF
set_units -time 1000ps

# Set the current design
current_design spi_slave_memory

# Define the clock on the uppercase port
create_clock -name "SCLK" -period 10000.0 -waveform {0.0 5000.0} [get_ports SCLK]

set_clock_transition 0.5 [get_clocks SCLK]
set_clock_gating_check -setup 0.0 

# Input delays on uppercase ports
set_input_delay -clock [get_clocks SCLK] -add_delay 0.002 [get_ports MOSI]
set_input_delay -clock [get_clocks SCLK] -add_delay 0.002 [get_ports CS]

# Output delay on uppercase port
set_output_delay -clock [get_clocks SCLK] -add_delay 0.002 [get_ports MISO]

set_wire_load_mode "segmented"
