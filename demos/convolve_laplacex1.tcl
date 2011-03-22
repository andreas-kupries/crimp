def op_convolve_laplacex {
    label {Laplace X}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    { 1  -2  1}
	    {-2   4 -2}
	    { 1  -2  1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
