def op_convolve_edgehog {
    label {Edge Grey/Horizontical+128}
    setup {
	# http://wiki.tcl.tk/9521
	variable K [crimp kernel make {
	    {-1 -1 -1}
	    { 0  0  0}
	    { 1  1  1}}]
	variable off [crimp map eval {apply {{x} { expr {($x + 128) % 256} }}}]
    }
    setup_image {
	show_image [crimp remap \
			[crimp filter convolve [crimp convert 2grey8 [base]] $K] \
			$off]
    }
}
