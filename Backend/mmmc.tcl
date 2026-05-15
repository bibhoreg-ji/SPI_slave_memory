#####################################################
# MMMC Setup for Innovus (with Captables)
# Design  : counter
# Process : TSMC 180nm BCD
# Corners : WC (setup), BC (hold)
######################################################

# ---- Paths ----
set lib_path "/DB/PDK/TSMC180BCD/STD_IO_LIB/BCD/STD_CELL/tcb018gbwp7t_290a/TSMCHOME/digital/Front_End/timing_power_noise/NLDM/tcb018gbwp7t_270a"
set cap_path "/DB/PDK/TSMC180BCD/STD_IO_LIB/BCD/STD_CELL/tcb018gbwp7t_290a/TSMCHOME/digital/Back_End/lef/tcb018gbwp7t_270a/techfiles/captable"

# ---- 1. Library Sets ----
create_library_set -name wc_lib -timing [list ${lib_path}/tcb018gbwp7twc.lib]
create_library_set -name bc_lib -timing [list ${lib_path}/tcb018gbwp7tbc.lib]

# ---- 2. RC Corners (Including Captables) ----
# Note: Ensure the filenames (e.g., _worst, _best) match your actual PDK files.
create_rc_corner -name wc_rc \
    -T 125 \
    -cap_table ${cap_path}/t018lo_1p6m_typical.captable

create_rc_corner -name bc_rc \
    -T -40 \
    -cap_table ${cap_path}/t018lo_1p6m_typical.captable

# ---- 3. Delay Corners ----
create_delay_corner -name wc_delay -library_set wc_lib -rc_corner wc_rc
create_delay_corner -name bc_delay -library_set bc_lib -rc_corner bc_rc

# ---- 4. Constraint Mode ----
# Updated path to match your latest synthesis results
create_constraint_mode -name func_mode \
    -sdc_files [list /DB/Projects/180BCD/QRNG/QC_MTech_01/spi_n/syn/spi_slave_memory.sdc]

# ---- 5. Analysis Views ----
create_analysis_view -name wc_view -delay_corner wc_delay -constraint_mode func_mode
create_analysis_view -name bc_view -delay_corner bc_delay -constraint_mode func_mode

# ---- 6. Final Assignment ----
set_analysis_view -setup {wc_view} -hold {bc_view}
