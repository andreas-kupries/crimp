def op_difference {
    label Difference
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	show_image [crimp alpha opaque [crimp difference [base 0] [base 1]]]
    }
}
