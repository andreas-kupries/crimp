def op_rof_max {
    label {Max Filter}
    setup_image {
	# Create a series of max-filtered images from the base,
	# with different kernel radii.

	show_slides [list \
			 [base] \
			 [crimp filter rank [base]  3 99.99] \
			 [crimp filter rank [base] 10 99.99] \
			 [crimp filter rank [base] 20 99.99]]
    }
}
