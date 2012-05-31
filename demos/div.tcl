def op_div {
    label Division
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp divide [base 0] [base 1]]
    }
}
