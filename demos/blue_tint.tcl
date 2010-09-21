def rgba_blue_tint {
    label Blue/Tint
    setup_image {
	set c [lindex [crimp split [base]] 2]
	set x [crimp blank grey8 {*}[crimp dimension $c] 0]
	show_image [crimp join 2rgb $x $x $c]
    }
}
