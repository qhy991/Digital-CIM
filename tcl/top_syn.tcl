set SCRIPT_FILE     script
source ./$SCRIPT_FILE/set_env.tcl
source -echo ./$SCRIPT_FILE/file_create.tcl

#force specific multiplier architectures 
#set_dp_smartgen_options -all_options auto
set cache_write  WORK/$file_version
set cache_read   WORK/$file_version

#set dft_mode 0
#set hdlin_enable_hier_map true
#set synopsys_auto_setup true
#set verification_clock_gate_hold_mode collapse_all_cg_cells
#set verification_clock_gate_edge_analysis true
#set compile_seqmap_propagate_constants false
#set hdlin_allow_partial_pg_netlist true
#set_optimize_registers false
#set dc_allow_rtl_pg true
#禁止cell打散
#set_ungroup <reference_or_cells> false;
#禁止打散，使用designware层次
#set_app_var compile_ultra_ungroup_dw false;



set_svf   $DATA_OUT/$working_design.svf
set_vsdc  $DATA_OUT/$working_design.vsdc


set_host_options -max_cores 16
set parallel_enable true
set CORE_NUM 16
# set CMP_OPTION "-no_autoungroup -scan"

#if {$do_scan == 1} { 
#    set CMP_OPTION [format "%s %s" -no_autoungroup -scan]
#} else {
#    set CMP_OPTION [format "%s" -no_autoungroup]
#}
#set compile_cmd  "compile $CMP_OPTION"
#alias do_compile $compile_cmd
#alias do_compile_inc $compile_cmd -inc

set search_path [list \
            ./ \
            ../ \
            /projects/school/buaa/release/sch/DCsyn_2	\
            ]

set target_library   [list ./source_file/${lib_slow}.db]
#set link_library     [list "*" ./source_file/${lib_slow}.db ./source_file/sadslsptb1p28x128m4b1w0cp0d0t0.db ./source_file/sadslsptb1p88x128m4b1w0cp0d0t0.db ./source_file/sadslsptb1p120x128m4b1w0cp0d0t0.db ./source_file/sadslsptb1p272x128m4b1w0cp0d0t0.db ./source_file/sadslsptb1p1532x128m4b1w0cp0d0t0.db ./source_file/sadslsptb1p2888x128m4b2w0cp0d0t0.db ./source_file/sadslsptb1p3060x64m4b2w0cp0d0t0.db ./source_file/sadslsptb1p4096x64m8b1w0cp0d0t0.db ./source_file/sadslsptb1p4096x128m4b2w0cp0d0t0.db ./source_file/HL55HRPLL2400NSCA01_SS1P08VN40C.db]
set link_library     [list "*" ./source_file/${lib_slow}.db ./source_file/HL55HRHDSP28x128B1M4W1SA10.db ./source_file/HL55HRHDSP88x128B1M4W1SA10.db ./source_file/HL55HRHDSP120x128B1M4W1SA10.db ./source_file/HL55HRHDSP272x128B1M4W1SA10.db ./source_file/HL55HRHDSP1532x128B1M4W1SA10.db ./source_file/HL55HRHDSP2888x128B2M4W1SA10.db ./source_file/HL55HRHDSP3060x64B2M4W1SA10.db ./source_file/HL55HRHDSP4096x64B1M8W1SA10.db ./source_file/HL55HRHDSP4096x64B4M4W1SA10.db ./source_file/HL55HRHDSP4096x128B2M4W1SA10.db ./source_file/HL55HRPLL2400NSCA01_SS1P08VN40C.db]
#set synthetic_library [list ] 
#set symbol_library [list generic.sdb]

#read_ddc "./source_file/MACRO_control1.ddc"
#read_ddc "./source_file/MACRO_control2.ddc"
#read_ddc "./source_file/MACRO_control3.ddc"
#read_ddc "./source_file/MACRO_control4.ddc"
define_design_lib WORK -path ./WORK/$file_version


##################################################################
## Read in Verilog Files    ##
##################################################################
# read_sverilog  ./$RTL_FILE/ram_dual.v
# read_sverilog  ./$RTL_FILE/fifo_512x10.v
# current_design $working_design
# link

#suppress_message UCN-1
#suppress_message VER-130
#suppress_message VER-129
#suppress_message VER-318
#suppress_message ELAB-311
#suppress_message VER-936


analyze -library work -format sverilog  -vcs "-f $RTL_FILE/filelist_dc.f"
#analyze -library work -format sverilog  ./source_file/ACCU.sv
#analyze -library work -format sverilog  {./source_file/VMM.sv \ 
#./source_file/AdderTree.sv \
#}


elaborate $working_design
report_attributes -design
current_design $working_design
link
uniquify

source -echo ./$SCRIPT_FILE/set_parameter.tcl

source -echo ./$SCRIPT_FILE/constraint_sdc.tcl
source -echo ./$SCRIPT_FILE/dont_touch.tcl

#read_saif -input design.saif -inst singlecelltest/u_singlecell
#change naming rule

report_clock > $RPT_OUT/clock.syn.rpt
report_clock -skew >> $RPT_OUT/clock.syn.rpt

current_design $working_design
set fix_mulitple_port_nets -feedthrough
set_fix_multiple_port_nets -all -buffer_constants
uniquify -force

##################################################################
## Optimization
##################################################################
change_names -rules sverilog -hierarchy

#set_clock_gating_style -sequential_cell none -max_fanout 30 -minimum_bitwidth 4
#compile_ultra -gate_clock -no_boundary -no_autoungroup 
compile_ultra -no_autoungroup
set_svf    -off
set_vsdc   -off


#compile > $RPT_OUT/compile.rpt
set_svf  -append  $DATA_OUT/$working_design.svf
set_vsdc -append  $DATA_OUT/$working_design.vsdc
compile -inc > $RPT_OUT/compile_inc.rpt
set_svf    -off
set_vsdc   -off
#compile -inc > $RPT_OUT/compile_inc1.rpt

#do_compile > $RPT_OUT/compile.rpt
#do_compile_inc > $RPT_OUT/compile_inc.rpt
#do_compile_inc > $RPT_OUT/compile_inc2.rpt
#
##change_names -rules verilog -hierarchy
current_design $working_design

##########################################

check_design  > $RPT_OUT/check_design.rpt
check_timing  > $RPT_OUT/check_timing.rpt
# set ports_clock_root [filter_collection [get_attribute [get_clocks] sources] object_class==port]
# group_path -name REGOUT -to [all_outputs] -weight 0.5
# group_path -name REGIN -from [remove_from_collection [all_inputs] ${ports_clock_root}] -weight 0.5
# group_path -name CLK -critical_range 0.2
# group_path -name CLK -critical 0.2 -weight 5

report_qor > $RPT_OUT/qor.rpt

report_area > $RPT_OUT/area.rpt
report_area -hierarchy > $RPT_OUT/area_hier.rpt
report_timing   -loops > $RPT_OUT/timing_loop.rpt
report_timing -path full -net -cap -input -tran -delay min -max_paths 200 -nworst 200 > $RPT_OUT/timing.min.rpt
report_timing -path full -net -cap -input -tran -delay max -max_paths 200 -nworst 200 > $RPT_OUT/timing.max.rpt
report_constraints -all_violators -verbose > $RPT_OUT/constraints.rpt
report_power > $RPT_OUT/power.rpt
###################################################################
## Saving Hierarchy
###################################################################
set bus_naming_style {%s[%d]} 
#####distinguish .v / .sv
write_file -f verilog -hierarchy -output $DATA_OUT/$working_design.sv
write_sdf -version 2.1 $DATA_OUT/$working_design.sdf
write_file -f ddc -hierarchy -output $DATA_OUT/$working_design.ddc

write_sdc $DATA_OUT/$working_design.sdc

#exit

