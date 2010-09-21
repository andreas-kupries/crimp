def op_convolve_sobelhvm {
    label {Sobel H+V/M}
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
	set gx [crimp filter convolve [base] $Kh]
	set gy [crimp filter convolve [base] $Kv]

	show_image [crimp alpha opaque \
			[crimp remap \
			     [crimp add \
				  [crimp multiply $gx $gx] \
				  [crimp multiply $gy $gy]] \
			     [crimp map sqrt]]]
    }
}
