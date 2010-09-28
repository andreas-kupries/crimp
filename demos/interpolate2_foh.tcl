def op_up_interpolate2foh {
    label Interpolate\u21912/FOH
    setup {
	# First order hold kernel.
	set K [crimp kernel make {{1 1 0}} 1]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp interpolate [base] 2 $K]]
    }
}
