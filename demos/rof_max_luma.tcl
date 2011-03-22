def op_rof_max_luma {
    label {Max Filter (Luma)}
    setup_image {
	# Create a series of max-filtered images from the luma of
	# the base, with different kernel radii.

	show_slides [apply {{base} {
	    set base [crimp convert 2grey8 $base]
	    return [list \
			$base \
			[crimp filter rank $base  3 99.99] \
			[crimp filter rank $base 10 99.99] \
			[crimp filter rank $base 20 99.99]]
	}} [base]]
    }
}
