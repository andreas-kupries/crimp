#!/bin/sh
# -*- tcl -*-
# The next line restarts with tclsh.\
exec tclsh "$0" ${1+"$@"}

if {[catch {
    package require Tcl 8.6
    package require Tk  8.6
}]} {
    package require Tcl 8.5
    package require Tk  8.5
    package require img::png
}
package require widget::scrolledwindow
package require widget::toolbar

# Access to critcl library from a local unwrapped critcl app.
set dir [file dirname [info script]]
lappend auto_path [file join $dir critcl.vfs lib]

# Direct access to the crimp package
source [file join $dir crimp.tcl]

#Use crimp as prebuilt package
#lappend auto_path $dir/lib
#package require crimp

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

proc demo_list {} {
    global dir demo dcurrent
    set dcurrent {}

    foreach f [glob -directory $dir/demos *.tcl] {
	set thedemo {}
	source $f
	#puts <$thedemo>
	set demo([dict get $thedemo name]) $thedemo
    }

    return [lsort -dict [array names demo]]
}

proc demo_label {name} {
    global demo
    return [dict get $demo($name) label]
}

proc demo_setup {name} {
    global demo dcurrent
    demo_close
    set dcurrent $name
    uplevel #0 [dict get $demo($name) setup]
    return
}

proc demo_close {} {
    global demo dcurrent
    if {$dcurrent eq {}} return

    destroy \
	{*}[winfo children .left]  \
	{*}[winfo children .right] \
	{*}[winfo children .top]   \
	{*}[winfo children .bottom]
    reframe

    uplevel #0 [dict get $demo($dcurrent) shutdown]
    set dcurrent {}
    return
}

proc def {name dict} {
    upvar 1 thedemo thedemo
    lappend thedemo setup {} shutdown {} {*}$dict name $name
    return
}

# # ## ### ##### ######## #############

proc reframe {} {
    grid forget .left .right .top .bottom

    grid .left   -row 2 -column 1               -sticky swen
    grid .right  -row 2 -column 3               -sticky swen
    grid .top    -row 1 -column 1 -columnspan 3 -sticky swen
    grid .bottom -row 3 -column 1 -columnspan 3 -sticky swen
    return
}

proc gui {} {
    widget::toolbar .t

    .t add button reset -text Reset -command reset
    set sep 1
    foreach demo [demo_list] {
	.t add button $demo \
	    -text      [demo_label $demo] \
	    -command   [list demo_setup $demo] \
	    -separator $sep
	set sep 0
    }
    .t add button exit -text Exit -command ::exit -separator 1

    widget::scrolledwindow .sc -borderwidth 1 -relief sunken
    widget::scrolledwindow .sl -borderwidth 1 -relief sunken
    canvas                 .c -width 800 -height 600 -scrollregion {-4000 -4000 4000 4000}
    listbox                .l -width 40 -selectmode extended -listvariable images

    ttk::frame .left
    ttk::frame .top
    ttk::frame .right
    ttk::frame .bottom

    .c create image {0 0} -anchor nw -tags photo
    .c itemconfigure photo -image [image create photo]

    .sl setwidget .l
    .sc setwidget .c

    grid .t  -row 0 -column 0 -columnspan 4 -sticky swen
    grid .sl -row 1 -column 0 -rowspan 3    -sticky swen
    grid .sc -row 2 -column 2               -sticky swen
    reframe

    bind .l <<ListboxSelect>> show_selection

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
    if {![llength $selection]} return
    show $selection
    return
}

proc show {indices} {
    global base
    set base {}
    foreach index $indices {
	lappend base [images_get $index]
    }
    reset
    return
}

proc reset {} {
    demo_close
    show_image [base]
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

# # ## ### ##### ######## #############

proc main {} {
    images_init
    gui
    after 100 {show 0}
    return
}

main
vwait forever
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
