def op_blank_random_hsv {
    label {Blank (Random, HSV)}
    active {
	expr {[bases] == 0}
    }
    setup {
	proc show {args} {
	    show_image \
		[crimp convert 2rgb \
		     [crimp join 2hsv \
			  [crimp convert 2grey8 [crimp::FITFLOAT [crimp noise random 800 600]]] \
			  [crimp convert 2grey8 [crimp::FITFLOAT [crimp noise random 800 600]]] \
			  [crimp convert 2grey8 [crimp::FITFLOAT [crimp noise random 800 600]]]]]
	    return
	}
	show
    }
}
