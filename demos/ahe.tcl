def op_ahe {
    label {AHE}
    setup_image {
	# Create a series of AHE images from the luma of
	# the base, with different kernel radii.
	show_slides [apply {{base} {
	    set base [crimp convert 2hsv [base]]
	    return [list \
			[base]\
			[crimp convert 2rgb [crimp filter ahe $base  3]] \
			[crimp convert 2rgb [crimp filter ahe $base 10]] \
			[crimp convert 2rgb [crimp filter ahe $base 20]] \
			[crimp convert 2rgb [crimp filter ahe $base 50]] \
			[crimp convert 2rgb [crimp filter ahe $base 100]]]
	}} [base]]
    }
}
