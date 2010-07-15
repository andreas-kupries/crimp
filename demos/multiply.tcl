def op_multiply {
    label Multiply
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	show_image [crimp multiply [base 0] [base 1]]
    }
}
