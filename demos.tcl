#!/bin/sh
# -*- tcl -*-
# The next line restarts with tclsh.\
exec tclsh "$0" ${1+"$@"}

if {[catch {
    package require Tcl 8.6
    package require Tk  8.6

    puts "Using Tcl/Tk 8.6"
}]} {
    package require Tcl 8.5
    package require Tk  8.5
    package require img::png

    puts "Using Tcl/Tk 8.5 + img::png"
}
package require widget::scrolledwindow
package require widget::toolbar

# Self dir
set dir [file dirname [file normalize [info script]]]

puts "In $dir"

set triedprebuilt 0
if {![file exists $dir/lib] ||
    [catch {
	set triedprebuilt 1

	puts "Trying prebuild crimp package"

	# Use crimp as prebuilt package
	lappend auto_path $dir/lib
	package require crimp

	puts "Using prebuilt crimp [package present crimp]"
	puts "At [package ifneeded crimp [package present crimp]]"
    } msg]} {

    if {$triedprebuilt} {
	puts "Trying to use a prebuilt crimp package failed ($msg)."
	puts ==\t[join [split $::errorInfo \n] \n==\t]
	puts "Falling back to dynamic compilation via local critcl package"
    }

    puts "Trying dynamically compiled crimp package"

    # Access to critcl library from a local unwrapped critcl app.
    lappend auto_path [file join $dir critcl.vfs lib]

    # Direct access to the crimp package
    source [file join $dir crimp.tcl]

    puts "Using dynamically compiled crimp package"
}

puts "Starting up ..."

# # ## ### ##### ######## #############

proc images_init {} {
    global dir images
    set images [glob -tails -directory $dir/images *]
    return
}

proc images_get {index} {
    global dir images

    set name  [lindex $images $index]
    set photo [image create photo -file [file join $dir images $name]]
    set image [crimp read tk $photo]
    image delete $photo

    return $image
}

# # ## ### ##### ######## #############

proc demo_init {} {
    global dir demo dcurrent demo_map
    set dcurrent {}

    array set demo {
	aaaaa {
	    label       Unmodified
	    cmd         demo_close
	    active      {expr {[bases] == 1}}
	    setup       {}
	    setup_image {}
	    shutdown    {}
	}
    }
    foreach f [glob -directory $dir/demos *.tcl] {
	set thedemo {}
	source $f
	set name [dict get $thedemo name]
	#puts <$thedemo>
	set demo($name) $thedemo
	lappend demo($name) cmd [list demo_use $name]
    }

    foreach name [demo_list] {
	set label [demo_label $name]
	set cmd   [demo_cmd   $name]
	set demo_map($label) $cmd
    }
    return
}

proc demo_list {} {
    global demo
    return [lsort -dict [array names demo]]
}

proc demo_cmd {name} {
    global demo
    return [dict get $demo($name) cmd]
}

proc demo_label {name} {
    global demo
    return [dict get $demo($name) label]
}

proc demo_use {name} {
    global times
    set times {}
    demo_setup $name
    demo_setup_image
    return
}

proc demo_setup {name} {
    global demo dcurrent
    demo_close
    set dcurrent $name
    demo_run_hook [dict get $demo($name) setup]
    return
}

proc demo_setup_image {} {
    global dcurrent demo times
    demo_run_hook [dict get $demo($dcurrent) setup_image]
    puts "Times: $times"
    return
}

proc demo_run_hook {script} {
    namespace eval ::DEMO [list demo_time_hook $script]
    return
}

proc demo_time_hook {script} {
    global  times
    set     x  [lindex [uplevel 1 [list time $script 1]] 0]
    lappend times [expr {double($x)/1E6}] [expr {double($x)/([crimp width [base]]*[crimp height [base]])}]
    return
}

proc demo_isactive {} {
    global dcurrent activedemos
    if {$dcurrent eq {}} {return 0}
    return [expr {[demo_label $dcurrent] in $activedemos}]
}

proc demo_close {} {
    global demo dcurrent

    if {![bases]} return
    show_image [base]

    if {$dcurrent eq {}} return
    reframe

    namespace eval   ::DEMO [dict get $demo($dcurrent) shutdown]
    namespace delete ::DEMO
    set dcurrent {}
    return
}

proc demo_usable {} {
    global demo activedemos
    set activedemos {}
    foreach n [demo_list] {
	set active [namespace eval ::DEMO [dict get $demo($n) active]]
	if {!$active} continue
	lappend activedemos [demo_label $n]
    }
    return
}

proc def {name dict} {
    upvar 1 thedemo thedemo
    lappend thedemo \
	setup       {} \
	setup_image {} \
	shutdown    {} \
	active      {
	    expr {[bases] == 1}
	} \
	{*}$dict name $name
    return
}

# # ## ### ##### ######## #############

proc reframe {} {
    destroy .left .right .top .bottom

    ttk::frame .left
    ttk::frame .top
    ttk::frame .right
    ttk::frame .bottom

    grid .left   -row 2 -column 2               -sticky swen
    grid .right  -row 2 -column 4               -sticky swen
    grid .top    -row 1 -column 2 -columnspan 3 -sticky swen
    grid .bottom -row 3 -column 2 -columnspan 3 -sticky swen
    return
}

proc gui {} {
    widget::toolbar .t

    .t add button exit -text Exit -command ::exit -separator 1

    widget::scrolledwindow .sc -borderwidth 1 -relief sunken
    widget::scrolledwindow .sl -borderwidth 1 -relief sunken
    widget::scrolledwindow .sd -borderwidth 1 -relief sunken
    #canvas                 .c -width 800 -height 600 -scrollregion {-4000 -4000 4000 4000}
    canvas                 .c -scrollregion {-4000 -4000 4000 4000}
    listbox                .l -width 40 -selectmode extended -listvariable images
    listbox                .d -width 40 -selectmode single   -listvariable activedemos

    .c create image {0 0} -anchor nw -tags photo
    .c itemconfigure photo -image [image create photo]

    .sl setwidget .l
    .sd setwidget .d
    .sc setwidget .c

    grid .t  -row 0 -column 0 -columnspan 4 -sticky swen
    grid .sl -row 1 -column 0 -rowspan 3    -sticky swen
    grid .sd -row 1 -column 1 -rowspan 3    -sticky swen
    grid .sc -row 2 -column 3               -sticky swen

    grid rowconfigure    . 0 -weight 0
    grid rowconfigure    . 1 -weight 0
    grid rowconfigure    . 2 -weight 1
    grid rowconfigure    . 3 -weight 0

    grid columnconfigure . 0 -weight 0
    grid columnconfigure . 1 -weight 0
    grid columnconfigure . 2 -weight 0
    grid columnconfigure . 3 -weight 1
    grid columnconfigure . 4 -weight 0

    reframe

    bind .l <<ListboxSelect>> show_selection
    bind .d <<ListboxSelect>> show_demo

    # Panning via mouse
    bind .c <ButtonPress-2> {%W scan mark   %x %y}
    bind .c <B2-Motion>     {%W scan dragto %x %y}

    # Cross hairs ...
    #.c configure -cursor tcross
    #crosshair::crosshair .c -width 0 -fill \#999999 -dash {.}
    #crosshair::track on  .c TRACK

    wm deiconify .
    return
}

# # ## ### ##### ######## #############

proc show_selection {} {
    set selection [.l curselection]
    #if {![llength $selection]} return
    show $selection
    demo_usable
    if {[demo_isactive]} {
	demo_setup_image
    } else {
	demo_close
    }
    return
}

proc show {indices} {
    global base
    set base {}
    foreach index $indices {
	lappend base [images_get $index]
    }
    return
}

proc show_demo {} {
    global demo_map activedemos
    set selection [.d curselection]
    if {![llength $selection]} return
    set index [lindex $selection 0]

    set label [lindex $activedemos $index]
    set command $demo_map($label)

    uplevel #0 $command
    return

}

# # ## ### ##### ######## #############
## DEMO API
##
## base       = Returns the currently selected and loaded input image.
## show_image = Display the image argument
## extendgui  = Extend the GUI with a single widget to the left of the
##              image display.  Multiple widgets can be had via a
##              frame.

proc show_image {image} {
    .c configure -scrollregion [list 0 0 {*}[crimp dimensions $image]]
    crimp write 2tk [.c itemcget photo -image] $image
    return
}

proc base {{i 0}} {
    global base
    return [lindex $base $i]
}

proc bases {} {
    global base
    return [llength $base]
}

# # ## ### ##### ######## #############

proc main {} {
    images_init
    demo_init
    gui
    after 100 {
	.l selection set 0
	event generate .l <<ListboxSelect>>
	after 100 {
	    .d selection set 0
	    event generate .d <<ListboxSelect>>
	}
    }
    return
}

main
vwait forever
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
