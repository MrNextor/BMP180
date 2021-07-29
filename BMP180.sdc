create_clock -period 100.0MHz -name {CLK} [get_ports {CLK}]

derive_clock_uncertainty

set_false_path -from [get_ports {IO_SCL IO_SDA}]   -to [all_clocks]
set_false_path -from [get_clocks {CLK}] -to [get_ports {IO_SCL IO_SDA}]