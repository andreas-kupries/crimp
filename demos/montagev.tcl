def op_montagev {
    label {Montage Top/Bottom}
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp width [base 0]] eq [crimp width [base 1]])
	  }
    }
    setup_image {
	show_image [crimp montage vertical [base 0] [base 1]]
    }
}
