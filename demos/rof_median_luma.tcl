def op_rof_median_luma {
    label {Median Filter (Luma)}
    setup_image {
	# Create a series of median-filtered images from the luma of
	# the base, with different kernel radii.

	show_slides [apply {{base} {
	    set base [crimp convert 2grey8 $base]
	    return [list \
			$base \
			[crimp rankfilter $base] \
			[crimp rankfilter $base 10] \
			[crimp rankfilter $base 20]]
	}} [base]]
    }
}
