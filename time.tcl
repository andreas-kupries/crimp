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
## Definitions to help with timing ...

lassign [::apply {{kernel} {
    set scale 0
    foreach r $kernel { foreach v $r { incr scale $v } }
    return [list [crimp read tcl grey8 $kernel] $scale]
}}  {
    {2  4  5  4 2}
    {4  9 12  9 4}
    {5 12 15 12 5}
    {4  9 12  9 4}
    {2  4  5  4 2}
}] K scale

lassign [::apply {{kernel} {
    set scale 0
    foreach r $kernel { foreach v $r { incr scale $v } }
    return [list [crimp read tcl grey8 $kernel] $scale]
}}  {
    {1 1 1 1 1}
    {1 1 1 1 1}
    {1 1 1 1 1}
    {1 1 1 1 1}
    {1 1 1 1 1}
}] B scaleb

lassign [::apply {{kernel} {
    set scale 0
    foreach r $kernel { foreach v $r { incr scale $v } }
    return [list [crimp read tcl grey8 $kernel] $scale]
}}  {
    {1 1 1 1 1}
}] Bh scalebx

set Bv [crimp flip transpose $Bh]

# # ## ### ##### ######## #############
## Time an operation

foreach image [glob -directory $dir/images *] {
    set photo [image create photo -file $image]
    set i [crimp read tk $photo]
    image delete $photo
    set i       [crimp join 2rgb {*}[lrange [crimp split $i] 0 2]]
    set npixels [expr {[crimp width $i] * [crimp height $i]}]

    puts "[file tail $image]:"

puts \tGauss
    set usec [lindex [time {
	crimp::convolve_rgb_const $i $K $scale
    }] 0]

    puts "\t\t$usec microseconds per iteration"
    puts "\t\t[expr {double($usec)/$npixels}] microseconds per pixel"

    puts \tBox
    set usec [lindex [time {
	crimp::convolve_rgb_const $i $B $scaleb
    }] 0]

    puts "\t\t$usec microseconds per iteration"
    puts "\t\t[expr {double($usec)/$npixels}] microseconds per pixel"

    puts \tBox/separable
    set usec [lindex [time {
	crimp::convolve_rgb_const [crimp::convolve_rgb_const $i $Bh $scalebx] $Bv $scalebx
    }] 0]

    puts "\t\t$usec microseconds per iteration"
    puts "\t\t[expr {double($usec)/$npixels}] microseconds per pixel"
}

# # ## ### ##### ######## #############
# # ## ### ##### ######## #############
# # ## ### ##### ######## #############
exit
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
