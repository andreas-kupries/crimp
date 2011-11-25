def op_alpha_blend_hsv_translated {
    label {Blend HSV/Translated}
    active { expr { [bases] == 2 } }
    setup {
	# We manage a cache of the blended images to make the
	# scrolling of the scale smoother over time. An improvement
	# would be to use timer events to precompute the various
	# blends.
	variable  cache
	array set cache {}
	set cache(255) [crimp place [base 0]  50  40]
	set cache(0)   [crimp place [base 1] -40 -50]
	variable fore  [crimp place [crimp convert 2hsv [base 0]]  50  40]
	variable back  [crimp place [crimp convert 2hsv [base 1]] -40 -50]
	variable alpha 255

	scale .left.s -variable DEMO::alpha \
	    -from 0 -to 255 \
	    -orient vertical \
	    -command [list ::apply {{thealpha} {
		variable cache
		variable fore
		variable back

		if {[info exists cache($thealpha)]} {
		    show_image  $cache($thealpha)
		    return
		}

		set theblend [crimp convert 2rgb [crimp alpha blend $fore $back $thealpha]]
		set cache($thealpha) $theblend
		show_image $theblend
		return
	    } ::DEMO}]

	pack .left.s -side left -fill both -expand 1
    }
}
