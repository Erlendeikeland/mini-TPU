proc get_compile_order {path top_level_file} {
    set python_path [auto_execok python.exe]
    set output [exec $python_path get_compile_order.py $path $top_level_file]
    return $output
}

set top_level_tb [lindex $do_argv 0]

quietly set path [file normalize [file dirname [info script]]]
set path [file dirname [file dirname $path]]

set compile_order [get_compile_order $path $top_level_tb]


vcom -reportprogress 300 -work work $compile_order