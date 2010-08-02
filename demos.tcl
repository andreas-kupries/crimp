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
package require widget::arrowbutton

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
    catch { spause }
    demo_run_hook [dict get $demo($dcurrent) setup_image]
    puts "Times: $times"
    return
}

proc demo_run_hook {script} {
    if {[catch {
	namespace eval ::DEMO [list demo_time_hook $script]
    }]} {
	set prefix "HOOK ERROR"
	puts $prefix[join [split $::errorInfo \n] \n$prefix]
    }
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
    slide_stop
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

proc reframe_part {p} {
    destroy    $p
    ttk::frame $p

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
## Slide show display and control

proc slide_gui {} {
    if {[winfo exists .top.pc]} return

    ttk::spinbox        .top.delay -textvariable ::delay -increment 1 -from 10 -to 5000

    widget::arrowbutton .top.forw  -orientation right   -command slide_forw
    widget::arrowbutton .top.backw -orientation left    -command slide_backw

    ttk::button         .top.pc    -image ::play::pause -command slide_pc
    ttk::button         .top.prev  -image ::play::prev  -command slide_step_prev
    ttk::button         .top.next  -image ::play::next  -command slide_step_next

    grid .top.backw -row 0 -column 0 -sticky swen
    grid .top.forw  -row 0 -column 1 -sticky swen

    grid .top.prev  -row 0 -column 2 -sticky swen
    grid .top.pc    -row 0 -column 3 -sticky swen
    grid .top.next  -row 0 -column 4 -sticky swen
    grid .top.delay -row 0 -column 5 -sticky swen
    return
}

proc slide_forw {} {
    global direction slides
    if {$direction > 0} return
    set direction 1
    set slides [lreverse $slides]
    return
}

proc slide_backw {} {
    global direction slides
    if {$direction < 0} return
    set direction -1
    set slides [lreverse $slides]
    return
}

proc slide_pc {} {
    global running
    if {$running} {
	spause
    } else {
	scontinue
    }
    return
}

proc slide_step_next {} {
    global direction
    spause
    if {$direction < 0 } { slide_forw ; snext }
    snext
    return
}

proc slide_step_prev {} {
    global direction
    spause
    if {$direction > 0 } { slide_backw ; snext }
    snext
    return
}

proc spause {} {
    .top.pc configure -image ::play::continue
    update idletasks
    slide_cycle_off
    return
}

proc scontinue {} {
    .top.pc configure -image ::play::pause
    update idletasks
    slide_cycle
    return
}

proc snext {} {
    global slides 
    if {![info exists slides] || ![llength $slides]} return
    display [cycle slides]
    return
}

namespace eval ::play {}
image create bitmap ::play::continue -data {
    #define continue_width 11
    #define continue_height 11
    static char continue_bits = {
	0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x3c, 0x00, 0xfc, 0x00, 0xfc,
	0x03, 0xfc, 0x00, 0x3c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00
    }
}

image create bitmap ::play::pause -data {
    #define pause_width 11
    #define pause_height 11
    static char pause_bits = {
	0x00, 0x00, 0x00, 0x00, 0x9c, 0x03, 0x9c, 0x03, 0x9c, 0x03, 0x9c,
	0x03, 0x9c, 0x03, 0x9c, 0x03, 0x9c, 0x03, 0x00, 0x00, 0x00, 0x00
    }
}

image create bitmap ::play::prev -data {
    #define prev_width 11
    #define prev_height 11
    static char prev_bits = {
	0x00, 0x00, 0x00, 0x00, 0x10, 0x01, 0x98, 0x01, 0xcc, 0x00, 0x66,
	0x00, 0xcc, 0x00, 0x98, 0x01, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00
}
}

image create bitmap ::play::next -data {
    #define next_width 11
    #define next_height 11
    static char next_bits = {
	0x00, 0x00, 0x00, 0x00, 0x44, 0x00, 0xcc, 0x00, 0x98, 0x01, 0x30,
	0x03, 0x98, 0x01, 0xcc, 0x00, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00
    }
}

proc slide_stop {} {
    slide_cycle_off
    reframe_part .top
    return
}

global delay direction running
set    delay 1000
set    direction 1
set    running 0

proc slide_cycle {} {
    global token delay running
    set running 1

    if {![string is integer $delay]|| ($delay < 1)} {
	set delay 100
    }

    set token [after $delay ::slide_cycle]

    snext
    return
}

proc slide_cycle_off {} {
    global token running
    set running 0
    catch { after cancel $token }
    return
}

proc cycle {lv} {
    upvar 1 $lv list
    set tail [lassign $list head]
    set list [list {*}$tail $head]
    return $head
}

# # ## ### ##### ######## #############
## DEMO API
##
## base       = Returns the currently selected and loaded input image.
## show_image = Display the image argument
## extendgui  = Extend the GUI with a single widget to the left of the
##              image display.  Multiple widgets can be had via a
##              frame.

proc show_slides {images} {
    global slides direction
    if {$direction < 0} {
	set slides [lreverse $images]
    } else {
	set slides $images
    }

    slide_gui
    scontinue
    return
}

proc show_image {image} {
    slide_stop
    display $image
    return
}

proc display {image} {
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
