#!/bin/sh
# -*- tcl -*-
# The next line restarts with tclsh.\
exec tclsh "$0" ${1+"$@"}

# With 8.5 we need a separate package to handle the PNG.
# With 8.6 we can use the one integrated in Tk.

package require Tcl 8.5
package require Tk
package require img::png

puts [join [info loaded] \n]

# Access to critcl library from a local unwrapped critcl app.
set dir [file dirname [info script]]
lappend auto_path [file join $dir critcl.vfs lib]

# Direct access to crimp package
source [file join $dir crimp.tcl]

# # ## ### ##### ######## #############
## Demo main - Skewed rotation

puts demo...
set photo [image create photo -file [file join $dir conformer.png]]
set image [crimp import $photo]
label .l -image $photo
pack .l
scale .s -from -180 -to 180 -orient horizontal -command \
    [list apply {{photo image angle} {
puts apply...|$angle|
	set s [expr {sin($angle * 0.017453292519943295769236907684886)}]
	set c [expr {cos($angle * 0.017453292519943295769236907684886)}]
	set matrix [list \
			[list $c $s 0] \
			[list [expr {-$s}] $c 0] \
			[list $s $s 1]]
puts matrix...
	set deformed [crimp matrix $image $matrix]
puts export...
	crimp export $photo $deformed
puts ...ok
    }} $photo $image]

pack .s -fill x

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
