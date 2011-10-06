# -*- tcl -*- 
## Tcl level definitions for crimp::pfm.
# # ## ### ##### ######## ############# #####################

# # ## ### ##### ######## ############# #####################

## Writing images in the PFM format (Portable Float Map).
## This is an unofficial derivative of PGM.
## Reference
##	 http://en.wikipedia.org/wiki/Netpbm_format

# # ## ### ##### ######## ############# #####################
## Reading PFM images is handled at the C level, and the command is
## directly fit into the ::crimp::read ensemble.

# # ## ### ##### ######## ############# #####################
## Writing PFM images is handled by providing the command sets
## expected by the standard 'write 2xxx' commands in the
## "crimp::core".

proc ::crimp::write::Str_pfm-plain_float {image} {
    # assert TypeOf (image) == float
    set res "F2 [::crimp dimensions $image]"

    binary scan [::crimp pixel $image] f* values
    foreach v $values {
	append res " " $v
    }
    return $res
}

proc ::crimp::write::Str_pfm-raw_float {image} {
    # assert TypeOf (image) == float
    return "F5 [::crimp dimensions $image] [::crimp pixel $image]"
}

proc ::crimp::write::Chan_pfm-plain_float {chan image} {
    # assert TypeOf (image) == float
    puts -nonewline $chan "F2 [::crimp dimensions $image] "

    binary scan [::crimp pixel $image] f* values
    foreach v $values {
	puts -nonewline $chan " $v"
    }
    return
}

proc ::crimp::write::Chan_pfm-raw_float {chan image} {
    # assert TypeOf (image) == float
    puts -nonewline $chan "F5 [::crimp dimensions $image] "
    puts -nonewline $chan [::crimp pixel $image]
    return
}

# # ## ### ##### ######## #############

proc ::crimp::writes_pfm-plain_fpcomplex {image} {
    # assert TypeOf (image) == fpcomplex
    set res "C2 [::crimp dimensions $image]"

    binary scan [::crimp pixel $image] f* values
    foreach v $values {
	append res " " $v
    }
    return $res
}

proc ::crimp::writes_pfm-raw_fpcomplex {image} {
    # assert TypeOf (image) == fpcomplex
    return "C5 [::crimp dimensions $image] [::crimp pixel $image]"
}

proc ::crimp::writec_pfm-plain_fpcomplex {chan image} {
    # assert TypeOf (image) == fpcomplex
    puts -nonewline $chan "C2 [::crimp dimensions $image] "

    binary scan [::crimp pixel $image] f* values
    foreach v $values {
	puts -nonewline $chan " $v"
    }
    return
}

proc ::crimp::writec_pfm-raw_fpcomplex {chan image} {
    # assert TypeOf (image) == fpcomplex
    puts -nonewline $chan "C5 [::crimp dimensions $image] "
    puts -nonewline $chan [::crimp pixel $image]
    return
}

# # ## ### ##### ######## #############
return
