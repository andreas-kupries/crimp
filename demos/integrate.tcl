def op_integrate {
    label Integrate
    setup_image {
	show_image \
	    [crimp convert 2grey8 \
		 [crimp integrate \
		      [crimp convert 2grey8 \
			   [base]]]]
    }
}
