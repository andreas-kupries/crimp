def op_div_translated {
    label Division/Translated
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp divide \
			     [crimp place [base 0] -50 -50] \
			     [crimp place [base 1] 60 70]]]
    }
}
