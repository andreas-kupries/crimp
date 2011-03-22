def op_convolve_sobelhvgm {
    label {Sobel Grey/H+V/M}
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
	set gx   [crimp filter convolve $grey $Kh]
	set gy   [crimp filter convolve $grey $Kv]

	show_image [crimp remap \
			[crimp add \
			     [crimp multiply $gx $gx] \
			     [crimp multiply $gy $gy]] \
			[crimp map sqrt]]
    }
}
