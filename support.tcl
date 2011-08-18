# -*- tcl -*-
# CRIMP Build Support Code
#
# (c) 2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries

# # ## ### ##### ######## #############

## Code factored out of the main crimp_xxx.tcl files

# # ## ### ##### ######## #############

proc crimp_source_cproc {accept reject} {
    set here [file dirname [file normalize [info script]]]

    foreach pa $accept {
	foreach filename [lsort -dict [glob -nocomplain -tails -directory $here $pa]] {
	    set take 1
	    foreach pr $reject {
		if {![string match $pr $filename]} continue
		set take 0
		break
	    }
	    if {!$take} continue

	    #critcl::msg -nonewline " \[[file rootname [file tail $filename]]\]"

	    set chan [open $here/$filename r]
	    set name ::crimp::[gets $chan]
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
	    ::critcl::cproc $name $params ok $body
	}
    }
    return
}
