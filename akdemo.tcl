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

# # ## ### ##### ######## #############
##

proc gui {} {
    widget::toolbar .t
    .t add button origin -text Original    -command sorigin
    .t add button invert -text Invert      -command sinvert
    .t add button red    -text Red         -command {srgbchan 0}
    .t add button green  -text Green       -command {srgbchan 1}
    .t add button blue   -text Blue        -command {srgbchan 2}
    .t add button ired   -text iRed        -command {sirgbchan 0}
    .t add button igreen -text iGreen      -command {sirgbchan 1}
    .t add button iblue  -text iBlue       -command {sirgbchan 2}
    .t add button ilum   -text Luminosity  -command sluminosity
    .t add button iilum  -text iLuminosity -command siluminosity

    .t add button hue    -text Hue         -command {shsvchan 0}
    .t add button sat    -text Saturation  -command {shsvchan 1}
    .t add button val    -text Value       -command {shsvchan 2}

    .t add button rhr    -text {RGB <-> HSV} -command srgbhsvrgb
    .t add button hr     -text {HSV as RGB}  -command shsvasrgb

    .t add button exit   -text Exit        -command ::exit -separator 1

    widget::scrolledwindow .sl -borderwidth 1 -relief sunken
    widget::scrolledwindow .sc -borderwidth 1 -relief sunken
    listbox                .l -width 40 -selectmode single \
	-listvariable images
    canvas                 .c -width 800 -height 600 -scrollregion {-4000 -4000 4000 4000}

    .c create image {0 0} -anchor nw -tags photo ;#-outline red
    .c itemconfigure photo -image [image create photo]


    .sl setwidget .l
    .sc setwidget .c

    pack .t  -fill both -expand 0 -side top -anchor w
    pack .sl -fill both -expand 1 -padx 4 -pady 4 -side left
    pack .sc -fill both -expand 1 -padx 4 -pady 4 -side right

    bind .l <<ListboxSelect>> useSelection

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

proc useSelection {} {
    set selection [.l curselection]
    if {![llength $selection]} return

    show [.l get $selection]
    return
}

proc show {name} {
    global dir base

    set photo [image create photo -file [file join $dir images $name]]
    set base  [crimp read_tk $photo]
    image delete $photo

    sorigin
    return
}

proc sorigin {} {
    global base 
    setimage $base
    return
}

proc sinvert {} {
    global base 
    setimage [crimp invert_[typeof $base] $base]
    return
}

proc sluminosity {} {
    global base
    setimage  [crimp convert_[typeof $base]_grey8 $base] 
    return
}

proc siluminosity {} {
    global base
    set image [crimp invert_[typeof $base] $base]
    setimage  [crimp convert_[typeof $image]_grey8 $image]
    return
}


proc shsvasrgb {} {
    global base
    set image [crimp convert_[typeof $base]_hsv $base]
    lassign [crimp split_hsv $image] h s v
    set image [crimp join_rgb $h $s $v]
    setimage $image
    return
}


proc srgbhsvrgb {} {
    global base
    set image [crimp convert_[typeof $base]_hsv $base]
    set image [crimp convert_hsv_rgba $image]
    setimage $image
    return
}

proc shsvchan  {idx} {
    global base
    set image [crimp convert_[typeof $base]_hsv $base]
    setimage [lindex [crimp split_[typeof $image] $image] $idx]
    return
}

proc srgbchan  {idx} {
    global base
    setimage [lindex [crimp split_[typeof $base] $base] $idx]
    return
}

proc sirgbchan {idx} {
    global base
    set image [lindex [crimp split_[typeof $base] $base] $idx]
    setimage [crimp invert_[typeof $image] $image]
    return
}

proc setimage {i} {
    #puts si/[join [crimp dimensions $i] x]
    .c configure -scrollregion [list 0 0 {*}[crimp dimensions $i]]
    crimp write_[typeof $i]_tk [.c itemcget photo -image] $i
    return
}

proc typeof {image} {
    return [namespace tail [crimp type $image]]
}

proc main {} {
    global dir images
    gui

    set images [glob -tails -directory $dir/images *]
    after 100 [list show [lindex $images 0]]
    return
}

main
vwait forever
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
