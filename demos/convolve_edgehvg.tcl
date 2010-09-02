def op_convolve_edgehvg {
    label {Edge Grey/H+V}
    setup {
	# http://wiki.tcl.tk/9521
	variable Kh [crimp kernel make {
	    {-1 -1 -1}
	    { 0  0  0}
	    { 1  1  1}}]
	variable Kv [crimp kernel make {
	    {-1  0 1}
	    {-1  0 1}
	    {-1  0 1}}]
    }
    setup_image {
	set grey [crimp convert 2grey8 [base]]
	show_image [crimp add \
			[crimp filter convolve $grey $Kh] \
			[crimp filter convolve $grey $Kv]]
    }
}
