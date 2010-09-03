def op_montageh {
    label {Montage Left/Right}
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp height [base 0]] eq [crimp height [base 1]])
	  }
    }
    setup_image {
	show_image [crimp montage horizontal [base 0] [base 1]]
    }
}
