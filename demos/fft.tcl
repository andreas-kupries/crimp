def op_fft {
    label {Fourier Transform}
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
	set f  [crimp fft forward $g]
	set gr [crimp convert 2grey8 [crimp fft backward $f]]
	set d  [crimp difference $g $gr]

	set gd  [crimp convert 2rgb $g]
	set fd  [crimp convert 2rgb [crimp convert 2grey8 $f] $falsecolor]
	set grd [crimp convert 2rgb $gr]
	set dd  [crimp convert 2rgb $d $falsecolor]

	show_image \
	    [crimp montage vertical -align left \
		 [crimp montage horizontal \
		      [border $gd] \
		      [border $fd]] \
		 [crimp montage horizontal \
		      [border $dd] \
		      [border $grd]]]
    }
}
