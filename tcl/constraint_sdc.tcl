set compile_enable_constant_propagation_with_no_boundary_opt false
set timing_enable_multiple_clocks_per_reg true
set enable_recovery_removal_arcs true

create_clock -name CLK -period 4 -waveform { 0.4  2.4 } [get_pins PLL_inst/PLLOUT]
#create_clock -name CLK -period 4 -waveform { 0.4  2.4 } [get_ports clk] 

#create_generated_clock -name CLK_PLL -source [get_pins PLL_inst/CLKREF] -multiply_by 2 [get_pins PLL_inst/PLLOUT]
#set_input_delay 2.5 -clock CLK [all_inputs]
#set_output_delay 2.5 -clock CLK [all_outputs]
set_input_delay 2.5 -clock CLK [get_ports {CLK_IN NRST_IN M N O SLEEP BYPASS NCE_IN NWE_IN NOE_IN ADDR_IN DATA_IN ANALOG_READY ANALOG_DIN}]
set_output_delay 2.5 -clock CLK [get_ports {DATA_OUT DATA_DIR INT_OUT ANALOG_BITSEL}]
#set_clock_uncertainty -setup 0.1 clk 
#set_clock_uncertainty -hold  0.2 clk 
set_clock_uncertainty 0.5 [get_clocks CLK] 
#set_clock_uncertainty 0.5 [get_clocks CLK_PLL] 

#set_clock_transition         0.2 clk 
#set_clock_latency -source 0.9 [get_clocks clk]
#set_clock_latency 0.5 [get_clocks clk]
# 所有输出port的输出负载电容设置为10pf
#set_load 0.01 [all_output]
# 给所有输出端口设置负载
#set_fanout_load 2 [all_outputs] 
#set power_default_toggle_rate 0.1
#set power_default_static_probability 0.5
#set_switching_activity -tog  0.1  -static  0.5  in
#set_switching_activity -tog  0.03 -static  0.5  en_acc
#set_case_analysis  1 comp
#set_case_analysis  0 reset
#set_max_fanout 5
#set_fanout_load 5


#set_max_transition  1.0 [current_design]
#set_max_transition  -clock_path 0.90 [all_clocks]
#set_clock_transition 0.9 [all_clocks]
#set_input_transition 0.89 [all_inputs]

#set_max_area 0

#set_driving_cell -lib_cell NBUFFX2 -pin Z -no_design_rule  [all_inputs]
#set_load [load_of ${lib_slow}/NBUFFX2/INP] [all_outputs]
#set_load  0.02 [all_outputs]
#set_load  0.006484 [all_outputs]

#set_input_delay 3 -clock CLK_IN [all_inputs]
#set_input_delay -max 5 -clock CLK_IN  {PLUS_A PLUS_B}
#set_input_delay -min 2 -clock CLK_IN  {PLUS_A PLUS_B}
#set_output_delay 1 -clock CLK_IN {COUT SUM_OUT}

#PE4
#set_multicycle_path -hold   1 -from A -to B
#set_multicycle_path 1000 -setup -from [get_pins PLL_inst/RESET] -to [get_pins PLL_inst/LOCKOUT]
#set_multicycle_path 999 -hold  -from [get_pins PLL_inst/RESET] -to [get_pins PLL_inst/LOCKOUT]

# false path
set_false_path -from [get_ports NRST_IN]
#set_false_path -from [get_ports rst_n]
