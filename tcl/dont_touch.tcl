# set_dont_touch [get_cells ram_dual/**]
#为了防止在时钟路径上插入Buffer而恶化时序，所以对时钟网络设置Dont_touch_network属性，即综合的时候不对Clk信号行优化
#set dont_touch_network [get_clocks clk]
#set_dont_touch_network [get_pins adc_permute_inst/dout]
#set_dont_touch_network [get_ports sram_dout]

