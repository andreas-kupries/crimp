def effect_rehsv {
    label {Change HSV}
    setup {
	proc ::RE {args} {
	    global gh gs gv ghsv

	    set mh [crimp map gain $gh]
	    set ms [crimp map gain $gs]
	    set mv [crimp map gain $gv]

	    show_image [crimp convert 2rgb [crimp remap $ghsv $mh $ms $mv]]
	    return
	}

	set ::gh 1
	set ::gs 1
	set ::gv 1

	frame .f

	scale .f.gh -variable ::gh -from 0 -to 20 -resolution 0.01 -orient vertical -command ::RE
	scale .f.gs -variable ::gs -from 0 -to 20 -resolution 0.01 -orient vertical -command ::RE
	scale .f.gv -variable ::gv -from 0 -to 20 -resolution 0.01 -orient vertical -command ::RE

	pack .f.gh -side left -expand 1 -fill both
	pack .f.gs -side left -expand 1 -fill both
	pack .f.gv -side left -expand 1 -fill both

	extendgui .f

	set ::ghsv [crimp convert 2hsv [base]]

    }
    shutdown {
	unset ::gh ::gs ::gv ::ghsv
	destroy .f
    }
}
