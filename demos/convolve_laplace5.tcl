def op_convolve_laplace5 {
    label {Laplace 4+1}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    { 0  -1  0}
	    {-1   5 -1}
	    { 0  -1  0}} 1]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
