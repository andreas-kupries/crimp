def op_convolve_laplacex1 {
    label {Laplace X+1}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    { 1  -2  1}
	    {-2   5 -2}
	    { 1  -2  1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
