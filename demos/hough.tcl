def op_hough {
    label {Hough Transform}
    setup {
	variable falsecolor \
	    [crimp gradient rgb {0 255 0} {255 0 0} 256]

	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}
    }
    setup_image {
	variable falsecolor

	set g  [crimp convert 2grey8 [base]]
	set h  [crimp::hough_grey8 $g 255]

	array set stat [crimp statistics basic $h]
	array set stat $stat(channel)
	array set stat $stat(value)

	log "min    $stat(min)"
	log "max    $stat(max)"
	log "middle $stat(middle)"
	log "mean   $stat(mean)"
	log "var    $stat(variance)"
	log "stddev $stat(stddev)"

	set gd  [crimp convert 2rgb $g]
	set hd  [crimp convert 2rgb [crimp invert [crimp convert 2grey8 $h]] $falsecolor]

	show_image \
		 [crimp montage horizontal \
		      [border $gd] \
		      [border $hd]]
    }
}
