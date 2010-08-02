def op_interpolate2 {
    label Interpolate\u21912
    setup {
	# Tent kernel.
	set K [crimp kernel make {{1 2 1}} 2]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp interpolate [base] 2 $K]]
    }
}
