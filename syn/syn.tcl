# ====================================================================
# PROFESSIONAL CADENCE GENUS SYNTHESIS SCRIPT
# ====================================================================

# 1. DESIGN SETUP
set DESIGN bdi_dbi_encoder
set REPORTS_DIR "./reports"
set OUTPUTS_DIR "./outputs"

# Create clean directories for our files
file mkdir $REPORTS_DIR
file mkdir $OUTPUTS_DIR

puts "========================================================="
puts "   *** INITIATING HIGH-EFFORT SYNTHESIS RUN ***"
puts "   *** TARGET MODULE: $DESIGN ***"
puts "========================================================="

# 2. TECHNOLOGY LIBRARY SETUP 
set_db library /home/install/FOUNDRY/digital/90nm/dig/lib/slow.lib

# 3. READ & ELABORATE DESIGN
puts "\n--- STEP 1/5: READING HDL ---"
read_hdl -sv ${DESIGN}.sv
elaborate $DESIGN

puts "\n--- STEP 2/5: CHECKING DESIGN INTEGRITY ---"
check_design -unresolved

# 4. LOAD CONSTRAINTS (SDC)
puts "\n--- STEP 3/5: APPLYING TIMING CONSTRAINTS ---"
read_sdc constraints.sdc

# 5. HIGH-EFFORT SYNTHESIS EXECUTION
puts "\n--- STEP 4/5: RUNNING SYNTHESIS (HIGH EFFORT) ---"
set_db syn_generic_effort medium
set_db syn_map_effort high
set_db syn_opt_effort high

syn_generic
syn_map
syn_opt

# 6. GENERATE PROFESSIONAL REPORTS
puts "\n--- STEP 5/5: GENERATING VERIFICATION REPORTS ---"

report_timing > ${REPORTS_DIR}/${DESIGN}_timing.rpt
report_area -detail > ${REPORTS_DIR}/${DESIGN}_area.rpt
report_gates > ${REPORTS_DIR}/${DESIGN}_gates.rpt
report_power -detail > ${REPORTS_DIR}/${DESIGN}_power.rpt
report_qor > ${REPORTS_DIR}/${DESIGN}_qor.rpt

# 7. EXPORT NETLIST & DELAY FORMATS
puts "\n--- EXPORTING GATE-LEVEL FILES ---"
write_hdl > ${OUTPUTS_DIR}/${DESIGN}_netlist.v
write_sdc > ${OUTPUTS_DIR}/${DESIGN}_final.sdc

puts "========================================================="
puts "   *** SYNTHESIS COMPLETE ***"
puts "   *** Check the ./reports/ directory for your results. ***"
puts "========================================================="
gui_show
