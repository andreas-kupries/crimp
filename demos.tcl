#!/bin/sh
# -*- tcl -*-
# The next line restarts with tclsh.\
exec tclsh "$0" ${1+"$@"}

puts "CRIMP demos"

if {[catch {
    puts "Trying Tcl/Tk 8.6"

    package require Tcl 8.6
    package require Tk  8.6

    puts "Using  Tcl/Tk 8.6"
}]} {
    puts "Trying Tcl/Tk 8.5 + img::png"

    package require Tcl 8.5
    package require Tk  8.5
    package require img::png

    puts "Using  Tcl/Tk 8.5 + img::png"
}

package require widget::scrolledwindow
package require widget::toolbar
package require widget::arrowbutton
package require fileutil

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

    set cp [file join [file dirname $dir] lib critcl.vfs lib]

    puts "Looking for critcl in $cp"

    # Access to critcl library from a local unwrapped critcl app.
    lappend auto_path $cp
    package require critcl 2

    puts "Got:           [package ifneeded critcl [package present critcl]]"

    # Directly access the crimp package
    source         [file join $dir crimp.tcl]

    # and then force the compilation and loading of the C-level
    # primitives, instead of defering until use.
    critcl::cbuild [file join $dir crimp.tcl]

    puts "Using dynamically compiled crimp package"
}

puts "Starting up ..."

#puts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n[join [info loaded] \n]
#puts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# # ## ### ##### ######## #############

proc images_init {} {
    global dir images
    set images [lsort -dict [glob -tails -directory $dir/images *.png]]
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
    demo_setup $name
    demo_setup_image
    return
}

proc demo_use_image {} {
    demo_setup_image
    return
}

proc demo_setup {name} {
    global demo dcurrent
    demo_close
    set dcurrent $name
    demo_run_hook "\nsetup $name" [dict get $demo($name) setup]
    return
}

proc demo_setup_image {} {
    global dcurrent demo
    catch { spause }
    demo_run_hook image [dict get $demo($dcurrent) setup_image]
    return
}

proc demo_run_hook {label script} {
    if {[catch {
	namespace eval ::DEMO [list demo_time_hook $label $script]
    }]} {
	set prefix "HOOK ERROR "
	log $prefix[join [split $::errorInfo \n] \n$prefix] error
    }
    return
}

proc demo_time_hook {label script} {
    set x [lindex [uplevel 1 [list time $script 1]] 0]

    log "$label = [expr {double($x)/1E6}] seconds"
    if {![bases]} return
    set n [expr {[crimp width [base]]*[crimp height [base]]}]
    log "\t$n pixels"
    log "\t[expr {double($x)/$n}] uSeconds/pixel"
    return
}

proc demo_isactive {} {
    global dcurrent activedemos
    if {$dcurrent eq {}} {return 0}
    return [expr {[demo_label $dcurrent] in $activedemos}]
}

proc demo_close {} {
    global demo dcurrent

    if {![bases]} {

	if {$dcurrent eq {}} return
	namespace eval   ::DEMO [dict get $demo($dcurrent) shutdown]
	namespace delete ::DEMO
	reframe
	set dcurrent {}

	return
    }

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

proc log {msg {tags {}}} {
    log* $msg\n $tags
    return
}

proc log* {msg {tags {}}} {
    .log configure -state normal
    .log insert end $msg $tags
    .log see end
    .log configure -state disabled
    #update
    return
}

# # ## ### ##### ######## #############

proc reframe {} {
    destroy .left .right .top .bottom .slide

    ttk::frame .slide
    ttk::frame .left
    ttk::frame .top
    ttk::frame .right
    ttk::frame .bottom

    # The slide control is above the paneling
    grid .slide -row 0 -column 1 -sticky swen

    # And this is around the image display in the paneling
    grid .top    -row 0 -column 0 -sticky swen -in .r -columnspan 3
    grid .left   -row 1 -column 0 -sticky swen -in .r
    grid .right  -row 1 -column 2 -sticky swen -in .r
    grid .bottom -row 2 -column 0 -sticky swen -in .r -columnspan 3
    return
}

proc reframe_slide {} {
    destroy    .slide
    ttk::frame .slide

    grid .slide -row 0 -column 2 -columnspan 3 -sticky swen
    return
}

proc tags {tw} {
    $tw tag configure error   -background #EE5555
    $tw tag configure warning -background yellow
    $tw tag configure note \
	-background lightyellow  \
	-borderwidth 1 -relief sunken
    return
}

proc gui {} {
    widgets
    layout
    bindings
    reframe
    wm deiconify .
    return
}

proc widgets {} {
    widget::toolbar .t

    .t add button exit -text Exit -command ::exit -separator 1

    ttk::panedwindow .h -orient horizontal
    ttk::panedwindow .v -orient vertical

    ttk::frame .r
    ttk::frame .l

    widget::scrolledwindow .sl -borderwidth 1 -relief sunken ; # log
    widget::scrolledwindow .sc -borderwidth 1 -relief sunken ; # image canvas
    widget::scrolledwindow .si -borderwidth 1 -relief sunken ; # list (image)
    widget::scrolledwindow .sd -borderwidth 1 -relief sunken ; # list (demo)

    text .log -height 5 -width 10 -font {Helvetica -18}
    tags .log

    canvas   .c -scrollregion {-4000 -4000 4000 4000}
    listbox  .li -width 15 -selectmode extended -listvariable images
    listbox  .ld -width 30 -selectmode single   -listvariable activedemos

    .c create image {0 0} -anchor nw -tags photo
    .c itemconfigure photo -image [image create photo]
    return
}

proc layout {} {
    # Place scrollable parts into their managers.

    .sl setwidget .log
    .si setwidget .li
    .sd setwidget .ld
    .sc setwidget .c

    .h add .v
    .h add .r

    .v add .sl
    .v add .l

    # Toolbar/pseudo-menu @ top, with the paneling below.
    grid .t -row 0 -column 0 -sticky swen
    grid .h -row 1 -column 0 -sticky swen -columnspan 2

    grid rowconfigure    . 0 -weight 0
    grid rowconfigure    . 1 -weight 1
    grid columnconfigure . 0 -weight 1

    # Place the image and demo lists side by side.
    grid .si -row 0 -column 0 -rowspan 3 -sticky swen -in .l
    grid .sd -row 0 -column 1 -rowspan 3 -sticky swen -in .l

    grid rowconfigure    .l 0 -weight 1
    grid columnconfigure .l 0 -weight 1

    # Image display in the center of the right panel
    grid .sc -row 1 -column 1 -sticky swen -in .r

    grid rowconfigure    .r 0 -weight 0
    grid rowconfigure    .r 1 -weight 1
    grid rowconfigure    .r 2 -weight 0
    grid columnconfigure .r 0 -weight 0
    grid columnconfigure .r 1 -weight 1
    grid columnconfigure .r 2 -weight 0

    return
}

proc bindings {} {
    bind .li <<ListboxSelect>> show_selection
    bind .ld <<ListboxSelect>> show_demo

    # Panning via mouse
    bind .c <ButtonPress-2> {%W scan mark   %x %y}
    bind .c <B2-Motion>     {%W scan dragto %x %y}

    # Cross hairs ...
    #.c configure -cursor tcross
    #crosshair::crosshair .c -width 0 -fill \#999999 -dash {.}
    #crosshair::track on  .c TRACK
    return
}

# # ## ### ##### ######## #############

proc show_selection {} {
    set selection [.li curselection]
    #if {![llength $selection]} return
    show $selection
    demo_usable
    if {[demo_isactive]} {
	demo_use_image
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
    set selection [.ld curselection]
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
    if {[winfo exists .slide.pc]} return

    ttk::spinbox        .slide.delay -textvariable ::delay -increment 1 -from 10 -to 5000

    widget::arrowbutton .slide.forw  -orientation right   -command slide_forw
    widget::arrowbutton .slide.backw -orientation left    -command slide_backw

    ttk::button         .slide.pc    -image ::play::pause -command slide_pc
    ttk::button         .slide.prev  -image ::play::prev  -command slide_step_prev
    ttk::button         .slide.next  -image ::play::next  -command slide_step_next

    grid .slide.backw -row 0 -column 0 -sticky swen
    grid .slide.forw  -row 0 -column 1 -sticky swen

    grid .slide.prev  -row 0 -column 2 -sticky swen
    grid .slide.pc    -row 0 -column 3 -sticky swen
    grid .slide.next  -row 0 -column 4 -sticky swen
    grid .slide.delay -row 0 -column 5 -sticky swen
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
    .slide.pc configure -image ::play::continue
    update idletasks
    slide_cycle_off
    return
}

proc scontinue {} {
    .slide.pc configure -image ::play::pause
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
    reframe_slide
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
    #display [crimp gamma $image 2.2]
    #display [crimp degamma $image 2.2]
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
    #return [crimp degamma [lindex $base $i] 2.2]
    #return [crimp gamma [lindex $base $i] 2.2]
}

proc bases {} {
    global base
    return [llength $base]
}

proc thebases {} {
    global base
    return $base
}

# # ## ### ##### ######## #############

proc main {} {
    images_init
    demo_init
    gui
    after 100 {event generate .li <<ListboxSelect>>}
    return
    after 100 {
	.li selection set 0
	event generate .li <<ListboxSelect>>
	after 100 {
	    .ld selection set 0
	    event generate .ld <<ListboxSelect>>
	}
    }
    return
}

main
vwait forever
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
