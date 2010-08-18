def op_rof_median_subtract {
    label {Median Filter Bandpass}
    setup_image {
	# Create a series of median-filtered images from the base,
	# with different kernel radii, which are then subtracted from
	# the base, leaving a sort-of band-pass image.

	show_slides [list \
			 [base] \
			 [crimp alpha opaque [crimp subtract [base] [crimp filter rank [base]]]] \
			 [crimp alpha opaque [crimp subtract [base] [crimp filter rank [base] 10]]] \
			 [crimp alpha opaque [crimp subtract [base] [crimp filter rank [base] 20]]]]
    }
}
