def op_convolve_sobelhg {
    label {Sobel Grey/Horizontical}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    { 1  2  1}
	    { 0  0  0}
	    {-1 -2 -1}}]
    }
    setup_image {
	show_image [crimp filter convolve [crimp convert 2grey8 [base]] $K]
    }
}
