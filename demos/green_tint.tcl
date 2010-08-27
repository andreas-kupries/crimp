def rgba_green_tint {
    label Green/Tint
    setup_image {
	set c [lindex [crimp split [base]] 1]
	set x [crimp blank grey8 {*}[crimp dimension $c] 0]
	show_image [crimp join 2rgb $x $c $x]
    }
}
