def op_convolve_sobelh {
    label {Sobel Horizontical}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    { 1  2  1}
	    { 0  0  0}
	    {-1 -2 -1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
