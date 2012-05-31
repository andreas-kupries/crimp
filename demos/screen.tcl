def op_screen {
    label Screen
    active { expr { [bases] == 2 } }
    setup_image {
	show_image [crimp screen [base 0] [base 1]]
    }
}
