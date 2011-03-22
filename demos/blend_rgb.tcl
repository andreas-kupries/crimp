def op_alpha_blend_rgb {
    label {Blend RGB}
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup {
	# We manage a cache of the blended images to make the
	# scrolling of the scale smoother over time. An improvement
	# would be to use timer events to precompute the various
	# blends.
	variable  cache
	array set cache {}
	set cache(255) [base 0]
	set cache(0)   [base 1]
	variable alpha 255

	scale .left.s -variable DEMO::alpha \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command [list ::apply {{thealpha} {
		variable cache

		if {[info exists cache($thealpha)]} {
		    show_image  $cache($thealpha)
		    return
		}

		set theblend [crimp alpha blend [base 0] [base 1] $thealpha]
		set cache($thealpha) $theblend
		show_image $theblend
		return
	    } ::DEMO}]

	pack .left.s -side left -fill both -expand 1
    }
}
