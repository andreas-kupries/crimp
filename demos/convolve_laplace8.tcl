def op_convolve_laplace8 {
    label {Laplace 8}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    {-1  -1 -1}
	    {-1   8 -1}
	    {-1  -1 -1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
