def op_convolve_sobelhv {
    label {Sobel H/V}
    setup {
	# http://wiki.tcl.tk/9521
	variable Kv [crimp kernel make {
	    {1  0 -1}
	    {2  0 -2}
	    {1  0 -1}}]
	variable Kh [crimp kernel make {
	    { 1  2  1}
	    { 0  0  0}
	    {-1 -2 -1}}]
    }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp add \
			     [crimp filter convolve [base] $Kh] \
			     [crimp filter convolve [base] $Kv]]]
    }
}
