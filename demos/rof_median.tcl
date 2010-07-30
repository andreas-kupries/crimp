def op_rof_median {
    label {Median Filter}
    setup_image {
	# Create a series of median-filtered images from the base,
	# with different kernel radii.

	show_slides [list \
			 [base] \
			 [crimp rankfilter [base]] \
			 [crimp rankfilter [base] 10] \
			 [crimp rankfilter [base] 20]]
    }
}
