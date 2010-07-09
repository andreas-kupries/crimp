def op_alpha_blend_hsv {
    label {Blend HSV}
    setup {
	set ::X 255
	# We manage a cache of the blended images to make the
	# scrolling of the scale smoother over time. An improvement
	# would be to use timer events to precompute the various
	# blends.
	array set ::B {}
	set ::B(255) [base 0]
	set ::B(0)   [base 1]
	set ::FO [crimp convert 2hsv [base 0]]
	set ::BA [crimp convert 2hsv [base 1]]

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

		set blend [crimp convert 2rgb [crimp blend $::FO $::BA $alpha]]
		show_image $blend
		set ::B($alpha) $blend
		return
	    }}]
	extendgui .s
    }
    shutdown {
	destroy .s
	unset ::X ::B ::BA ::FO
    }
}
