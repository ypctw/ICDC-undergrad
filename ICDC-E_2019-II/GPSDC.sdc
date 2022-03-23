# operating conditions and boundary conditions #

set cycle 200        ;#clock period defined by designer

create_clock -period $cycle [get_ports clk]

set_dont_touch_network      [all_clocks]
set_ideal_network           [get_ports  clk]
set_clock_uncertainty  1    [all_clocks]
set_clock_latency      1    [all_clocks]

set_input_delay  -max 1    -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_input_delay  -min 0    -clock clk [remove_from_collection [all_inputs] [get_ports clk]]
set_output_delay -max 1    -clock clk [all_outputs] 
set_output_delay -min 0    -clock clk [all_outputs] 

set_load         0.1     [all_outputs]
set_drive        1       [all_inputs]

set_operating_conditions  -max slow  
set_wire_load_model -name tsmc13_wl10 -library slow                        

set_max_fanout 20 [all_inputs]

