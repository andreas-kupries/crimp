def op_max {
    label Max
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp max [base 0] [base 1]]
    }
}
