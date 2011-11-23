def op_difference_translated {
    label Difference/Translated
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp difference \
			     [crimp place [base 0] -50 -50] \
			     [crimp place [base 1] 60 70]]]
    }
}
