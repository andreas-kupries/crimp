def effect_wavy {
    label Wavy
    setup {
	proc ::W {args} {
	    global wa wb wc
	    show_image [crimp wavy [base] $wa $wb $wc]
	    return
	}

	set ::wa 1
	set ::wb 1
	set ::wc 1

	frame .f

	scale .f.wa -variable ::wa -from -20 -to 20 -resolution 0.01 -orient vertical -command ::W
	scale .f.wb -variable ::wb -from -20 -to 20 -resolution 0.01 -orient vertical -command ::W
	scale .f.wc -variable ::wc -from -20 -to 20 -resolution 0.01 -orient vertical -command ::W

	pack .f.wa -side left -expand 1 -fill both
	pack .f.wb -side left -expand 1 -fill both
	pack .f.wc -side left -expand 1 -fill both

	extendgui .f
    }
    shutdown {
	unset ::wa ::wb ::wc
	destroy .f
    }
}
