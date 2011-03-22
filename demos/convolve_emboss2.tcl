def op_convolve_embossb {
    label {Emboss (Suchenwirth)}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    {2  0  0}
	    {0 -1  0}
	    {0  0 -1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
