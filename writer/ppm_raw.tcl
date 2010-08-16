# -*- tcl -*-
# # ## ### ##### ######## #############
# Writing images to the raw (binary) sub-format of the PPM format
# (Portable Pix Map).
# See http://en.wikipedia.org/wiki/Netpbm_format

namespace eval ::crimp::write {}

proc ::crimp::write::2ppmraw {path image} {
    set type [crimp::TypeOf $image]
    if {$type ne "rgb"} {
	# Strip the alpha channel, or transform the colorspace, before
	# running the result through the writer.
	set image [crimp convert 2rgb $image]
    }

    # Note how the internal pixel data is already in the form needed
    # by the format.

    fileutil::writeFile -encoding binary $path \
	"P6 [crimp dimensions $image] 255 [crimp pixel $image]"
    return
}

# # ## ### ##### ######## #############
return
