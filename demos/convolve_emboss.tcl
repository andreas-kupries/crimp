def op_convolve_emboss {
    label {Emboss}
    setup {
	variable K [crimp kernel make {
	    {-1 -1 1}
	    {-1 -1 1}
	    { 1  1 1}}]
    }
    setup_image {
	show_image [crimp alpha opaque [crimp filter convolve [base] $K]]
    }
}
