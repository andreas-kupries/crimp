def effect_color_xyz {
    label {CIE XYZ from RGB}
    setup_image {
	show_image [crimp color mix [base] [crimp color rgb2xyz]]
    }
}
