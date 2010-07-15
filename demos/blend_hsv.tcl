def op_alpha_blend_hsv {
    label {Blend HSV}
    active { expr {[bases] == 2} }
    setup {
	set ::ALPHA 255
	# We manage a cache of the blended images to make the
	# scrolling of the scale smoother over time. An improvement
	# would be to use timer events to precompute the various
	# blends.
	array set ::CACHE {}
	set ::CACHE(255) [base 0]
	set ::CACHE(0)   [base 1]
	set ::FORE [crimp convert 2hsv [base 0]]
	set ::BACK [crimp convert 2hsv [base 1]]

	scale .left.s -variable ::ALPHA \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command [list ::apply {{alpha} {
		if {[info exists ::CACHE($alpha)]} {
		    show_image $::CACHE($alpha)
		    return
		}

		set blend [crimp convert 2rgb [crimp blend $::FORE $::BACK $alpha]]
		show_image $blend
		set ::CACHE($alpha) $blend
		return
	    }}]

	pack .left.s -side left -fill both -expand 1
    }
    shutdown {
	unset ::ALPHA ::CACHE ::BACK ::FORE
    }
}
