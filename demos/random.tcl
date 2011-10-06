def op_blank_random {
    label {Blank (Random)}
    active {
	expr {[bases] == 0}
    }
    setup {
	proc show {args} {
	    show_image [crimp convert 2grey8 \
			    [crimp::FITFLOAT \
				 [crimp noise random 800 600]]]
	    return
	}
	show
    }
}
