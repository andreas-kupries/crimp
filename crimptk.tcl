# -*- tcl -*-
# CRIMP :: Tk == C Runtime Image Manipulation Package :: Tk Photo Conversion.
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3
package require critcl::util 1

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::TK, no proper compiler found."
}

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5
critcl::tk

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources crimptk_tcl.tcl

# # ## ### ##### ######## #############
## Chart helpers.

critcl::tsources plot.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. stubs and types)

critcl::api import crimp 0

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
}

# # ## ### ##### ######## #############
## Read and execute the tk-specific .crimp files in the current directory.

critcl::owns operator/*tk*.crimp
::apply {{here} {
    foreach filename [lsort [glob -nocomplain -directory [file join $here operator] *tk*.crimp]] {
	#critcl::msg -nonewline " \[[file rootname [file tail $filename]]\]"
	set chan [open $filename]
	set name [gets $chan]
	set params "Tcl_Interp* interp"
	set number 2
	while {1} {
	    incr number
	    set line [gets $chan]
	    if {$line eq ""} {
		break
	    }
	    append params " $line"
	}
	set body "\n#line $number \"[file tail $filename]\"\n[read $chan]"
	close $chan
	namespace eval ::crimp [list ::critcl::cproc $name $params ok $body]
    }
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::TK failed."
}

# # ## ### ##### ######## #############

package provide crimp::tk 0
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
