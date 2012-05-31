def op_multiply {
    label Multiply
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp multiply [base 0] [base 1]]
    }
}
