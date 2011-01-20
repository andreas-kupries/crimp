def op_bilateral {
    label {Bilteral Filtering}
    setup {
	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}
    }
    setup_image {

	set g  [crimp convert 2grey8 [base]]

	set ba [crimp::bilateral_grey8 $g  5 1]
	set bb [crimp::bilateral_grey8 $g 10 1]

	set bd  [crimp convert 2rgb [base]]
	set gd  [crimp convert 2rgb $g]
	set bad [crimp convert 2rgb $ba]
	set bbd [crimp convert 2rgb $bb]

	show_image \
	    [crimp montage vertical -align left \
		 [crimp montage horizontal \
		      [border $bd] \
		      [border $gd]] \
		 [crimp montage horizontal \
		      [border $bad] \
		      [border $bbd]]]
    }
}
