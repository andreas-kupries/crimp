def op_convolve_laplace9 {
    label {Laplace 8+1}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    {-1  -1 -1}
	    {-1   9 -1}
	    {-1  -1 -1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
