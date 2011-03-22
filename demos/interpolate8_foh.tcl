def op_up_interpolate8foh {
    label Interpolate\u21918/FOH
    setup {
	# Tent kernel.
	set K [crimp kernel make {{0 1 1}} 1]
    }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp interpolate xy \
			     [crimp interpolate xy \
				  [crimp interpolate xy [base] \
				       2 $K] \
				  2 $K] \
			     2 $K]]
    }
}
