def op_rof_min_luma {
    label {Min Filter (Luma)}
    setup_image {
	# Create a series of min-filtered images from the luma of
	# the base, with different kernel radii.

	show_slides [apply {{base} {
	    set base [crimp convert 2grey8 $base]
	    return [list \
			$base \
			[crimp filter rank $base  3 0] \
			[crimp filter rank $base 10 0] \
			[crimp filter rank $base 20 0]]
	}} [base]]
    }
}
