def op_ahe_luma {
    label {AHE (Luma)}
    setup_image {
	# Create a series of AHE images from the luma of
	# the base, with different kernel radii.

	show_slides [apply {{base} {
	    set base [crimp convert 2grey8 $base]
	    return [list \
			$base \
			[crimp filter ahe $base  3] \
			[crimp filter ahe $base 10] \
			[crimp filter ahe $base 20] \
			[crimp filter ahe $base 50] \
			[crimp filter ahe $base 100]]
	}} [base]]
    }
}
