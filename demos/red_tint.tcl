def rgba_red_tint {
    label Red/Tint
    setup_image {
	set c [lindex [crimp split [base]] 0]
	set x [crimp blank grey8 {*}[crimp dimension $c] 0]
	show_image [crimp join 2rgb $c $x $x]
    }
}
