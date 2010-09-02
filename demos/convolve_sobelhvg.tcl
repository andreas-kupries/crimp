def op_convolve_sobelhvg {
    label {Sobel Grey/H+V}
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
	set grey [crimp convert 2grey8 [base]]
	show_image [crimp add \
			     [crimp filter convolve $grey $Kh] \
			     [crimp filter convolve $grey $Kv]]
    }
}
