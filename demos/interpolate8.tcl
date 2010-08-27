def op_up_interpolate8 {
    label Interpolate\u21918
    setup {
	# Tent kernel.
	set K [crimp kernel make {{1 2 1}} 2]
    }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp interpolate \
			     [crimp interpolate \
				  [crimp interpolate [base] \
				       2 $K] \
				  2 $K] \
			     2 $K]]
    }
}
