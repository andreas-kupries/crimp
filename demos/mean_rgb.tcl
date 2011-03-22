def op_mean_rgb {
    label {Mean Filter (RGB)}
    setup_image {
	# Create a series of mean-filtered images from the base,
	# with different kernel radii.

	set g [base]

	# radius => window
	#  1 - 3x3
	#  2 - 5x5
	#  3 - 7x7
	# 10 - 21x21
	# 20 - 41x41

	show_slides [list \
			 $g \
			 [crimp filter mean $g 1] \
			 [crimp filter mean $g 2] \
			 [crimp filter mean $g] \
			 [crimp filter mean $g 10] \
			 [crimp filter mean $g 20]]
    }
}
