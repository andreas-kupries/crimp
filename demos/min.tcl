def op_min {
    label Min
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp min [base 0] [base 1]]
    }
}
