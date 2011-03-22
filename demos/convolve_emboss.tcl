def op_convolve_emboss {
    label {Emboss (Ulis)}
    setup {
	# http://wiki.tcl.tk/10543
	variable K [crimp kernel make {
	    {-1 -1 1}
	    {-1 -1 1}
	    { 1  1 1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
