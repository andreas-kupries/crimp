def op_alpha_blend_rgb {
    label {Blend RGB}
    setup {
	set ::X 255
	set ::BLACK [crimp blank rgba 800 600 0 0 0 255]
	# We manage a cache of the blended images to make the
	# scrolling of the scale smoother over time. An improvement
	# would be to use timer events to precompute the various
	# blends.
	array set ::B {}
	set ::B(255) [base 0]
	set ::B(0)   [base 1]

	scale .s \
	    -variable ::X \
	    -from 0 \
	    -to 255 \
	    -orient vertical \
	    -command [list ::apply {{alpha} {
		if {[info exists ::B($alpha)]} {
		    show_image $::B($alpha)
		    return
		}

		set blend [crimp blend [base 0] [base 1] $alpha]
		show_image [crimp setalpha $blend $::BLACK]
		set ::B($alpha) $blend
		return
	    }}]
	extendgui .s
    }
    shutdown {
	destroy .s
	unset ::X ::BLACK ::B
    }
}
