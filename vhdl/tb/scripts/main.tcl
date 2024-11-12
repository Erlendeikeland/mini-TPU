proc get_compile_order {path top_level_file} {
    set python_path [auto_execok python.exe]
    set output [exec $python_path get_compile_order.py $path $top_level_file]
    return $output
}

quietly set script_path [pwd]
quietly set project_path [file join $script_path ../../]
quietly set work_path [file join $script_path work]

quietly set cmdl_args [lrange $argc 0 end]

if {$cmdl_args == 1} {
    quietly set src_path $project_path
    quietly set top_level_file [lindex $do_argv 0]
} elseif {$cmdl_args == 2} {
    quietly set src_path [lindex $do_argv 0]
    quietly set top_level_file [lindex $do_argv 1]
} else {
    error
}

if {![file exists $work_path]} {
    file mkdir $work_path
} else {
    foreach file [glob -nocomplain -directory $work_path *] {
        #file delete -force $file
    }
}

vlib work
vmap work $work_path

quietly set compile_order [get_compile_order $src_path $top_level_file]
vcom -reportprogress 300 -2008 -work work $compile_order

if {[runStatus] != "nodesign" && [find instances -bydu -nodu $top_level_file] == [string tolower "/$top_level_file"]} {
    puts "Design loaded, restarting simulation"
    restart -f
} else {
    puts "Design not loaded, loading design"
    vsim -quiet work.$top_level_file
}

run -all