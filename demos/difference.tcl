def op_difference {
    label Difference
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	show_image [crimp setalpha \
			[crimp difference [base 0] [base 1]] \
			[crimp blank grey8 {*}[crimp dimensions [base]] 255]]
    }
}
