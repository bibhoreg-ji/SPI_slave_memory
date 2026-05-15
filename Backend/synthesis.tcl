####################################################### 
# Cadence Genus Synthesis Script
# Design  : spi_slave_memory
# Process : TSMC 180nm BCD
# User    : QC_MTech_01
####################################################### 

# ----------------------------------------------------
# 1. Search paths & Libraries
# ----------------------------------------------------
set_attribute hdl_search_path {/DB/Projects/180BCD/QRNG/QC_MTech_05/spi/rtl/} /
set_attribute lib_search_path {/DB/PDK/TSMC180BCD/STD_IO_LIB/BCD/STD_CELL/tcb018gbwp7t_290a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcb018gbwp7t_270a/} /
set_attribute library {tcb018gbwp7twc.lib} /
set_attribute information_level 6 /

# ----------------------------------------------------
# 2. Design-specific variables
# ----------------------------------------------------
set myFiles {spi_slave_memory.v}
set basename spi_slave_memory
set myClk sclk
set myPeriod_ps 10000000; # 50 MHz SPI Clock (adjusted from 10ns to 20ns for safety)
set myInDelay_ns 2.0;  # Input delay (MOSI/CS)
set myOutDelay_ns 2.0; # Output delay (MISO)
set runname spi_mem_180bcd
set out_dir "/DB/Projects/180BCD/QRNG/QC_MTech_05/spi/syn/"

# ----------------------------------------------------
# 3. Read & elaborate RTL
# ----------------------------------------------------
read_hdl -sv ${myFiles}
elaborate ${basename}

# ----------------------------------------------------
# 4. Clock and timing constraints
# ----------------------------------------------------
# Define the SPI clock
define_clock -name ${myClk} -period ${myPeriod_ps} [get_ports ${myClk}]

# Define external delays
external_delay -input ${myInDelay_ns} -clock [get_clocks ${myClk}] [get_ports mosi]
external_delay -input ${myInDelay_ns} -clock [get_clocks ${myClk}] [get_ports cs]
external_delay -output ${myOutDelay_ns} -clock [get_clocks ${myClk}] [get_ports miso]

# Prevent Genus from adding clock gating (useful for simple SPI modules)
set_attribute lp_insert_clock_gating false /

# Set clock transition for a realistic 180nm slope
dc::set_clock_transition 0.5 [get_clocks ${myClk}]

# ----------------------------------------------------
# 5. Synthesis
# ----------------------------------------------------
syn_generic
syn_map
syn_opt

# ----------------------------------------------------
# 6. Output files
# ----------------------------------------------------
write_hdl -mapped > ${out_dir}/${basename}_mapped.v
write_sdc > ${out_dir}/${basename}.sdc
write_sdf -timescale ns > ${out_dir}/${basename}_delay.sdf

# ----------------------------------------------------
# 7. Reports
# ----------------------------------------------------
report timing > ${out_dir}/${basename}_timing.rep
report gates  > ${out_dir}/${basename}_cells.rep
report power  > ${out_dir}/${basename}_power.rep

puts "Synthesis Finished Successfully for SPI Slave Memory!"
