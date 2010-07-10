def op_alpha_blend_rgb {
    label {Blend RGB}
    setup {
	set ::ALPHA 255
	set ::BLACK [crimp blank rgba 800 600 0 0 0 255]
	# We manage a cache of the blended images to make the
	# scrolling of the scale smoother over time. An improvement
	# would be to use timer events to precompute the various
	# blends.
	array set ::CACHE {}
	set ::CACHE(255) [base 0]
	set ::CACHE(0)   [base 1]

	scale .left.s -variable ::ALPHA \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command [list ::apply {{alpha} {
		if {[info exists ::CACHE($alpha)]} {
		    show_image $::CACHE($alpha)
		    return
		}

		set blend [crimp blend [base 0] [base 1] $alpha]
		show_image [crimp setalpha $blend $::BLACK]
		set ::CACHE($alpha) $blend
		return
	    }}]

	pack .left.s -side left -fill both -expand 1
    }
    shutdown {
	unset ::ALPHA ::BLACK ::CACHE
    }
}
