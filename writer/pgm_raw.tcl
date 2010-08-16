# -*- tcl -*-
# # ## ### ##### ######## #############
# Writing images to the raw (binary) sub-format of the PGM format
# (Portable Grey Map).
# See http://en.wikipedia.org/wiki/Netpbm_format

namespace eval ::crimp::write {}
proc ::crimp::write::2pgmraw_grey8 {path image} {

    set type [crimp::TypeOf $image]
    if {$type ne "grey8"} {
	return -code error "expected image type grey8"
    }

    # Note how the internal pixel data is already in the form needed
    # by the format.

    fileutil::writeFile -encoding binary $path \
	"P5 [crimp dimensions $image] 255 [crimp pixel $image]"
    return
}

# # ## ### ##### ######## #############
return
