def effect_color_xyz2 {
    label {CIE XYZ from RGB, separate}
    setup {
	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}
    }
    setup_image {
	lassign [crimp split [crimp color mix [base] [crimp color rgb2xyz]]] \
	    x y z
	show_image [crimp montage vertical [border $x] [border $y] [border $z]]
    }
}
