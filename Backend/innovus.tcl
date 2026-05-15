#######################################################
# Innovus Place & Route Script
# Design  : spi
# Process : TSMC 180nm BCD (6 metal layers - M1-M4 used)
# User    : QC_MTech_05
# Note    : All routing (signal + power) constrained to M1-M4
#######################################################

set design_name    spi_slave_memory
set netlist_path   ../syn/spi_slave_memory_mapped2.v
set lef_path       /DB/PDK/TSMC180BCD/STD_IO_LIB/BCD/STD_CELL/tcb018gbwp7t_290a/TSMCHOME/digital/Back_End/lef/tcb018gbwp7t_270a/lef/tcb018gbwp7t_6lm.lef
set std_cell_gds   /DB/PDK/TSMC180BCD/STD_IO_LIB/BCD/STD_CELL/tcb018gbwp7t_290a/TSMCHOME/digital/Back_End/gds/tcb018gbwp7t_270a/tcb018gbwp7t.gds

# ==========================================================
# 1. DESIGN INITIALIZATION
# ==========================================================

set init_verilog    ${netlist_path}
set init_top_cell   ${design_name}
set init_lef_file   ${lef_path}
set init_mmmc_file  "mmmc.tcl"

set init_pwr_net    "VDD"
set init_gnd_net    "VSS"

init_design
setDesignMode -process 180

# Enable OCV so all optimization phases use the same timing model
setAnalysisMode -analysisType onChipVariation

# ---------------- Global Routing Layer Constraints ----------------
# Constrain ALL routing (signal + power) to M1-M4
setNanoRouteMode -routeBottomRoutingLayer 1
setNanoRouteMode -routeTopRoutingLayer    4
setNanoRouteMode -routeWithTimingDriven   true

# Constrain stripe via stacks so power vias never punch above M4
setAddStripeMode -stacked_via_top_layer    METAL4 \
                 -stacked_via_bottom_layer METAL1

puts "=== Design initialized, OCV enabled, routing constrained to M1-M4 ==="

# ==========================================================
# 2. FLOORPLAN
#    Aspect ratio 1.0, utilization 0.7, 5 um margins.
# ==========================================================

floorPlan -s 120 60  7 7 7 7

set fp_box [dbGet top.fPlan.box]
set fp_box [join $fp_box]    ;# flatten in case it's nested
puts "=== Floorplan box: $fp_box ==="
puts "=== Die width  : [expr {[lindex $fp_box 2] - [lindex $fp_box 0]}] um ==="
puts "=== Die height : [expr {[lindex $fp_box 3] - [lindex $fp_box 1]}] um ==="

saveDesign ${design_name}_floorplan.enc

puts "=== Floorplan created ==="

############################################################
# SPI SLAVE MEMORY PIN PLACEMENT
#
# Core Size
# ----------
# Width  = 133 um
# Height = 73 um
############################################################

setPinAssignMode -pinEditInBatch true


############################################################
# LEFT SIDE : 14 PINS
############################################################
editPin \
    -pin {REG1_OUT[5] REG1_OUT[4] REG1_OUT[3] REG1_OUT[2] 
          REG1_OUT[1] REG1_OUT[0]
          REG0_OUT[7] REG0_OUT[6] REG0_OUT[5] REG0_OUT[4] 
          REG0_OUT[3] REG0_OUT[2] REG0_OUT[1] REG0_OUT[0]
    } \
    -side left \
    -layer METAL2 \
    -spreadType SIDE \
    -start {0 8} \
    -end {0 65} \
    -fixedPin

############################################################
# RIGHT SIDE : 12 PINS
############################################################
editPin \
    -pin {
        REG4_OUT[0] REG4_OUT[1] REG4_OUT[2] REG4_OUT[3]
        REG4_OUT[4] REG4_OUT[5] REG4_OUT[6] REG4_OUT[7]
        REG3_OUT[7] REG3_OUT[6]
        REG3_OUT[5] REG3_OUT[4]
    } \
    -side right \
    -layer METAL2 \
    -spreadType SIDE \
    -start {133 65} \
    -end {133 8} \
    -fixedPin


############################################################
# BOTTOM SIDE : 14 PINS
############################################################
editPin \
    -pin {
         REG3_OUT[3] REG3_OUT[2]
         REG3_OUT[1] REG3_OUT[0]
         REG2_OUT[7] REG2_OUT[6] REG2_OUT[5] REG2_OUT[4]
         REG2_OUT[3] REG2_OUT[2] REG2_OUT[1] REG2_OUT[0]
         REG1_OUT[7] REG1_OUT[6]
    } \
    -side bottom \
    -layer METAL3 \
    -spreadType SIDE \
    -start {125 0} \
    -end {8 0} \
    -fixedPin

############################################################
# TOP SIDE : SPI PINS
############################################################

editPin \
    -pin {CS} \
    -side top \
    -layer METAL2 \
    -assign {10 73} \
    -fixedPin

editPin \
    -pin {MISO} \
    -side top \
    -layer METAL2 \
    -assign {30 73} \
    -fixedPin

editPin \
    -pin {MOSI} \
    -side top \
    -layer METAL2 \
    -assign {60 73} \
    -fixedPin

editPin \
    -pin {RST_N} \
    -side top \
    -layer METAL2 \
    -assign {90 73} \
    -fixedPin

editPin \
    -pin {SCLK} \
    -side top \
    -layer METAL2 \
    -assign {125 73} \
    -fixedPin


setPinAssignMode -pinEditInBatch false

puts "=== Pins placed on left/right sides ==="

# ==========================================================
# 4. POWER PLANNING
#    Ring : M3 (L/R) + M4 (T/B)
#    Stripes : M4
#    All PG vias constrained to stay within M1-M4
# ==========================================================

globalNetConnect VDD -type pgpin -pin VDD -inst * -all
globalNetConnect VSS -type pgpin -pin VSS -inst * -all

addRing \
    -nets {VDD VSS} \
    -type core_rings \
    -layer {top METAL4 bottom METAL4 left METAL3 right METAL3} \
    -width 1.0 \
    -spacing 0.5

addStripe \
    -nets {VDD VSS} \
    -layer METAL4 \
    -width 0.5 \
    -spacing 5 \
    -set_to_set_distance 20

# sroute constrained to M1-M4 for all PG connections
sroute -connect {blockPin padPin padRing corePin} \
       -layerChangeRange       {METAL1 METAL4} \
       -crossoverViaLayerRange {METAL1 METAL4} \
       -targetViaLayerRange    {METAL1 METAL4} \
       -allowJogging      1 \
       -allowLayerChange  1

# --- Create top-level VDD/VSS physical pins on M4 ring ---
foreach net {VDD VSS} {
    set pg_net [dbGet -p top.pgNets.name $net]
    if {$pg_net == "0x0"} { continue }

    foreach wire [dbGet $pg_net.sWires] {
        if {[dbGet $wire.layer.name] != "METAL4"} { continue }

        set bbox [dbGet $wire.box]
        set llx [lindex $bbox 0 0]
        set lly [lindex $bbox 0 1]
        set urx [lindex $bbox 0 2]
        set ury [lindex $bbox 0 3]

        # Place a 1x1 um pin at the center of this M4 wire
        set cx [expr {($llx + $urx) / 2.0 - 0.5}]
        set cy [expr {($lly + $ury) / 2.0 - 0.5}]

        createPhysicalPin $net -net $net -layer METAL4 \
            -rect [list $cx $cy [expr {$cx + 1.0}] [expr {$cy + 1.0}]]

        puts "Created $net pin at ($cx, $cy)"
        break
    }
}

saveDesign ${design_name}_power.enc
puts "=== Power planning complete (constrained to M1-M4) ==="

# ==========================================================
# 5. WELL TAP CELLS
# ==========================================================

addWellTap -cell TAPCELLBWP7T -cellInterval 30 -prefix TAP

# ==========================================================
# 6. PLACEMENT
# ==========================================================

placeDesign
checkPlace
saveDesign ${design_name}_placed.enc
puts "============================================== Placement complete =================================================="

# ==========================================================
# 7. TIE CELL INSERTION
#    Must happen BEFORE pre-CTS opt so optimization sees tied logic.
# ==========================================================

addTieHiLo -cell "TIEHBWP7T TIELBWP7T" -prefix TIE

# ==========================================================
# 8. PRE-CTS OPTIMIZATION
# ==========================================================

optDesign -preCTS
puts "============================================== PRE-CTS OOPTIMIZATION complete =================================================="

# ==========================================================
# 9. CLOCK TREE SYNTHESIS
#    Constrain clock routing to M1-M4 as well
# ==========================================================

set_ccopt_property buffer_cells   {BUFFD1BWP7T BUFFD2BWP7T BUFFD4BWP7T BUFFD8BWP7T}
set_ccopt_property inverter_cells {GINVD1BWP7T GINVD2BWP7T GINVD8BWP7T}


puts "============================================== buff complete =================================================="



# Restrict clock routing layers to M1-M4 using route_type mechanism.
# Define a named route type with the desired layer range, then bind it
# to all clock net types (top, trunk, leaf).
create_route_type -name clk_route_m1_m4 \
                  -bottom_preferred_layer METAL1 \
                  -top_preferred_layer    METAL4

set_ccopt_property -net_type top   route_type clk_route_m1_m4
set_ccopt_property -net_type trunk route_type clk_route_m1_m4
set_ccopt_property -net_type leaf  route_type clk_route_m1_m4

delete_ccopt_clock_tree_spec
create_ccopt_clock_tree_spec
ccopt_design

# ==========================================================
# 10. POST-CTS OPTIMIZATION
# ==========================================================

optDesign -postCTS

# ==========================================================
# 11. CTS REPORTS
# ==========================================================

report_ccopt_clock_trees          > ${design_name}_cts_trees.rpt
report_ccopt_skew_groups          > ${design_name}_cts_skew.rpt
report_clock_timing -type summary > ${design_name}_clock_summary.rpt
report_clock_timing -type skew    > ${design_name}_clock_skew.rpt
report_clock_timing -type latency > ${design_name}_clock_latency.rpt

saveDesign ${design_name}_cts.enc
puts "=== CTS complete ==="

# ==========================================================
# 12. ROUTING
#    NanoRoute already constrained to M1-M4 globally above.
# ==========================================================

# Re-assert routing constraints just before routeDesign as a safety net
setNanoRouteMode -routeBottomRoutingLayer 1
setNanoRouteMode -routeTopRoutingLayer    4

routeDesign

# ==========================================================
# 13. POST-ROUTE OPTIMIZATION
# ==========================================================

optDesign -postRoute
optDesign -postRoute -hold
optDesign -postRoute -setup -hold

saveDesign ${design_name}_routed.enc
puts "=== Routing and post-route opt complete ==="

# ==========================================================
# 14. FILLER CELLS
# ==========================================================

addFiller -cell {FILL8BWP7T FILL4BWP7T FILL2BWP7T FILL1BWP7T} -prefix FILLER

# ==========================================================
# 15. PHYSICAL VERIFICATION
# ==========================================================

set_verify_drc_mode -limit 1000
verify_drc
verifyConnectivity

puts "=== Internal verification complete ==="

# ==========================================================
# 16. FINAL TIMING REPORTS
# ==========================================================

# Setup report
setAnalysisMode -checkType setup
report_timing -check_type setup -path_type full_clock > ${design_name}_setup_timing.rpt

# Hold report
setAnalysisMode -checkType hold
report_timing -check_type hold  -path_type full_clock > ${design_name}_hold_timing.rpt

# timeDesign manages its own check type internally
timeDesign -postRoute       -prefix final_setup -outDir timingReports
timeDesign -postRoute -hold -prefix final_hold  -outDir timingReports

summaryReport > ${design_name}_summary.rpt

puts "=== Timing reports generated ==="

# ==========================================================
# 17. EXPORT GDS
# ==========================================================

setStreamOutMode -labelAllPinShape true

streamOut ${design_name}_final.gds \
    -units 1000 \
    -mapFile gds2.map \
    -merge ${std_cell_gds}

# ==========================================================
# 18. EXPORT NETLISTS FOR CALIBRE LVS
# ==========================================================

saveNetlist ${design_name}_postroute.v -phys
saveNetlist ${design_name}_nofill.v    -includePowerGround
saveNetlist ${design_name}_sim.v

# ==========================================================
# 19. EXPORT TIMING FILES
# ==========================================================

write_sdf ${design_name}_postroute.sdf
write_sdc ${design_name}_postroute.sdc

# ==========================================================
# 20. EXPORT DEF AND SAVE FINAL DATABASE
# ==========================================================

defOut ${design_name}_final.def
saveDesign ${design_name}_innovus_final.enc

puts ""
puts "========================================================"
puts "  Place & Route Finished Successfully!"
puts "  Design  : ${design_name}"
puts "  Process : TSMC 180nm BCD (6 metal layers, M1-M4 used)"
puts "========================================================"
