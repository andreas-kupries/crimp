# -*- tcl -*-
# CRIMP == C Runtime Image Manipulation Package
#
# (c) 2010 Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

#package require Tk
package require critcl

# # ## ### ##### ######## #############
## Implementation.

catch {
    critcl::cheaders -g
    critcl::debug memory symbols
}

critcl::config tk 1
critcl::cheaders c/*.h cop/*.c
critcl::csources c/*.c
critcl::tsources crimp_tcl.tcl
critcl::tsources plot.tcl

critcl::cinit {
    crimp_imagetype_init ();
} {}

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
    #include <image_type.h>
    #include <image.h>
    #include <rank.h>
    #include <color.h>
    #include <util.h>
}

# # ## ### ##### ######## #############
## Read and execute all .crimp files in the current directory.

foreach filename [lsort [glob -nocomplain -directory [file join [file dirname [file normalize [info script]]] operator] *.crimp]] {
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

# # ## ### ##### ######## #############
## Pull in the Tcl layer aggregating the C primitives into useful
## commands.
##
## NOTE: This is for the interactive use of crimp.tcl. When used as
##       plain package the 'tsources' declaration at the top ensures
##       the distribution and use of the Tcl layer.

source [file join [file dirname [file normalize [info script]]] crimp_tcl.tcl]

# This can fail when compiling via 'critcl -pkg', because snit may not
# be a visible package to the starkit. Have to think more about how to
# separate the pieces. Plot should likely be its own package.
catch {
    source [file join [file dirname [file normalize [info script]]] plot.tcl]
}

# # ## ### ##### ######## #############
## Ready. Export.

package provide crimp 1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
