def op_difference {
    label Difference
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp alpha opaque [crimp difference [base 0] [base 1]]]
    }
}
