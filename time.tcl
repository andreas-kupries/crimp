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
#package require widget::scrolledwindow
#package require widget::toolbar
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

# # ## ### ##### ######## #############
## Definitions to help with timing ...

proc s {usec} { expr {double($usec)/1e6} }

# # ## ### ##### ######## #############
## Time an operation

foreach image $argv {
    puts ""
    puts "[file tail $image]:"

    set sz [file size $image]

    set usec [lindex [time {
	set data [fileutil::cat -translation binary $image]
    }] 0]

    puts ""
    puts "R\t$usec microseconds to read $sz bytes"
    puts "\t[s $usec] seconds to read $sz bytes"
    puts "\t[expr {double($usec)/$sz}] microseconds/byte"

    set usec [lindex [time {
	set image [crimp read pgm $data]
    }] 0]

    puts ""
    puts "C\t$usec microseconds to convert $sz bytes"
    puts "\t[s $usec] seconds to convert $sz bytes"
    puts "\t[expr {double($usec)/$sz}] microseconds/byte"

    set npixels [expr {[crimp width $image] * [crimp height $image]}]

    puts ""
    puts "\t$usec microseconds to convert $npixels pixels"
    puts "\t[s $usec] seconds to convert $npixels pixels"
    puts "\t[expr {double($usec)/$npixels}] microseconds/pixel"

    set usec [lindex [time {
	set stats [crimp statistics basic $image]
    }] 0]

    puts ""
    puts "S\t$usec microseconds for statistics of $npixels pixels"
    puts "\t[s $usec] seconds for statistics of $npixels pixels"
    puts "\t[expr {double($usec)/$npixels}] microseconds/pixel"

    unset image
}

# # ## ### ##### ######## #############
# # ## ### ##### ######## #############
# # ## ### ##### ######## #############
exit
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
