def op_min {
    label Min
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	show_image [crimp min [base 0] [base 1]]
    }
}
