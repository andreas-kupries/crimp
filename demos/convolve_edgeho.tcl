def op_convolve_edgeho {
    label {Edge Horizontical+128}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    {-1 -1 -1}
	    { 0  0  0}
	    { 1  1  1}}]
	variable off [crimp map eval {apply {{x} { expr {($x + 128) % 256} }}}]
    }
    setup_image {
	show_image [crimp alpha opaque \
			[crimp remap \
			     [crimp filter convolve [base] $K] \
			     $off]]
    }
}
