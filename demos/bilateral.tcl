def op_bilateral {
    label {Bilteral Filtering}
    setup {
	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}

	proc stretch {i} {
	    set s [crimp statistics basic $i]
	    set min [dict get $s channel luma min]
	    set max [dict get $s channel luma max]
	    crimp remap $i [crimp map stretch $min $max]
	}
    }
    setup_image {

	set g  [crimp convert 2grey8 [base]]

	# Filter
	set ba [crimp::bilateral_grey8 $g  5 4]
	set bb [crimp::bilateral_grey8 $g 10 4]

	# Residuals. Scaled to magnify any differences.
	set da [stretch [crimp::difference $g $ba]]
	set db [stretch [crimp::difference $g $bb]]

	set bd  [crimp convert 2rgb [base]]
	set gd  [crimp convert 2rgb $g]
	set bad [crimp convert 2rgb $ba]
	set bbd [crimp convert 2rgb $bb]
	set dad [crimp convert 2rgb $da]
	set dbd [crimp convert 2rgb $db]

	show_image \
	    [crimp montage vertical -align left \
		 [crimp montage horizontal \
		      [border $bd] \
		      [border $gd]] \
		 [crimp montage horizontal \
		      [border $bad] \
		      [border $bbd]] \
		 [crimp montage horizontal \
		      [border $dad] \
		      [border $dbd]]]
    }
}
