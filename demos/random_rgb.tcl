def op_blank_random_rgb {
    label {Blank (Random, RGB)}
    active {
	expr {[bases] == 0}
    }
    setup {
	proc show {args} {
	    show_image \
		[crimp join 2rgb \
		     [crimp convert 2grey8 [crimp::FITFLOAT [crimp noise random 800 600]]] \
		     [crimp convert 2grey8 [crimp::FITFLOAT [crimp noise random 800 600]]] \
		     [crimp convert 2grey8 [crimp::FITFLOAT [crimp noise random 800 600]]]]
	    return
	}
	show
    }
}
