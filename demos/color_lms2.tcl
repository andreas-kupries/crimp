def effect_color_lms2 {
    label {CIE LMS/RLAB from RGB, separate}
    setup {
	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}
    }
    setup_image {
	lassign [crimp split [crimp color mix [base] [crimp color rgb2lms rlab]]] \
	    l m s
	show_image [crimp montage vertical [border $l] [border $m] [border $s]]
    }
}
