def op_rof_min {
    label {Min Filter}
    setup_image {
	# Create a series of min-filtered images from the base,
	# with different kernel radii.

	show_slides [list \
			 [base] \
			 [crimp filter rank [base]  3 0] \
			 [crimp filter rank [base] 10 0] \
			 [crimp filter rank [base] 20 0]]
    }
}
