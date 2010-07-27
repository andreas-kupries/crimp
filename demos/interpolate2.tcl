def op_interpolate2 {
    label Interpolate\u21912
    setup {
	# Tent kernel.
	set K [crimp kernel make {{1 2 1}} 2]
    }
    setup_image {
	set n [crimp interpolate [base] 2 $K]
	set m [crimp blank grey8 {*}[crimp dimensions $n] 255]
	show_image [crimp setalpha $n $m]
    }
}
