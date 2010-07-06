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
##

proc gui {} {
    widget::toolbar .t
    .t add button origin -text Original    -command show_origin
    .t add button invert -text Invert      -command show_invert
    .t add button red    -text Red         -command {show_rgbchan 0}
    .t add button green  -text Green       -command {show_rgbchan 1}
    .t add button blue   -text Blue        -command {show_rgbchan 2}
    .t add button ired   -text iRed        -command {show_irgbchan 0}
    .t add button igreen -text iGreen      -command {show_irgbchan 1}
    .t add button iblue  -text iBlue       -command {show_irgbchan 2}
    .t add button ilum   -text Luminosity  -command show_luminosity
    .t add button iilum  -text iLuminosity -command show_iluminosity

    .t add button hue    -text Hue         -command {show_hsvchan 0}
    .t add button sat    -text Saturation  -command {show_hsvchan 1}
    .t add button val    -text Value       -command {show_hsvchan 2}

    .t add button rhr    -text {RGB <-> HSV} -command show_rgbhsvrgb
    .t add button hr     -text {HSV as RGB}  -command show_hsvasrgb

    .t add button flipv  -text \u2191\u2193 -command show_flip_v
    .t add button fliph  -text \u2194       -command show_flip_h
    .t add button fliptp -text \\           -command show_transpose
    .t add button fliptv -text /            -command show_transverse

    .t add button exit   -text Exit        -command ::exit -separator 1

    widget::scrolledwindow .sl -borderwidth 1 -relief sunken
    widget::scrolledwindow .sc -borderwidth 1 -relief sunken
    listbox                .l -width 40 -selectmode single \
	-listvariable images
    canvas                 .c -width 800 -height 600 -scrollregion {-4000 -4000 4000 4000}

    set ::scala 256
    scale .s -from 0 -to 256 -orient horizontal -variable ::scala

    set ::gamma 1.0
    scale .g -from 0.1 -to 5.0 -orient horizontal -variable ::gamma -resolution 0.1

    .c create image {0 0} -anchor nw -tags photo
    .c itemconfigure photo -image [image create photo]

    .sl setwidget .l
    .sc setwidget .c

    pack .t  -fill both -expand 0 -side top -anchor w
    pack .sl -fill both -expand 1 -padx 4 -pady 4 -side left
    pack .s  -fill both -expand 0 -side top
    pack .g  -fill both -expand 0 -side top
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

proc resolarize {v} {
    global baseb
    setimageb [crimp solarize [baseb] $v]
    return
}

proc regamma {v} {
    global baseb
    setimageb [crimp degamma [baseb] $v]
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
    set base  [crimp read tk $photo]
    image delete $photo

    show_origin
    return
}

proc base {} {
    global base
    return $base
}

proc baseb {} {
    global baseb
    return $baseb
}

proc show_origin {} {
    setimage [base]
    return
}

proc show_invert {} {
    setimage [crimp invert [base]]
    return
}

proc show_luminosity {} {
    setimage [crimp convert 2grey8 [base]]
    return
}

proc show_iluminosity {} {
    setimage [crimp convert 2grey8 [crimp invert [base]]]
    return
}

proc show_hsvasrgb {} {
    setimage [crimp join 2rgb {*}[crimp split [crimp convert 2hsv [base]]]]
    return
}

proc show_rgbhsvrgb {} {
    setimage [crimp convert 2rgba [crimp convert 2hsv [base]]]
    return
}

proc show_hsvchan  {idx} {
    setimage [lindex [crimp split [crimp convert 2hsv [base]]] $idx]
    return
}

proc show_rgbchan  {idx} {
    setimage [lindex [crimp split [base]] $idx]
    return
}

proc show_irgbchan {idx} {
    setimage [crimp invert [lindex [crimp split [base]] $idx]]
    return
}

proc show_flip_v {} {
    setimage [crimp flip vertical [base]]
    return
}

proc show_flip_h {} {
    setimage [crimp flip horizontal [base]]
    return
}

proc show_transpose {} {
    setimage [crimp flip transpose [base]]
    return
}

proc show_transverse {} {
    setimage [crimp flip transverse [base]]
    return
}

proc setimage {i} {
    global baseb scala
    set baseb $i
    .c configure -scrollregion [list 0 0 {*}[crimp dimensions $i]]
    crimp write 2tk [.c itemcget photo -image] $i
    .s configure -command resolarize
    .g configure -command regamma
    return
}

proc setimageb {i} {
    set basec $i
    .c configure -scrollregion [list 0 0 {*}[crimp dimensions $i]]
    crimp write 2tk [.c itemcget photo -image] $i
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
