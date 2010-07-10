def effect_wavy {
    label Wavy
    setup {
	proc ::W {args} {
	    global WA WB WC
	    show_image [crimp wavy [base] $WA $WB $WC]
	    return
	}

	set ::WA 1
	set ::WB 1
	set ::WC 1

	scale .left.wa -variable ::WA -from -20 -to 20 -resolution 0.01 -orient vertical -command ::W
	scale .left.wb -variable ::WB -from -20 -to 20 -resolution 0.01 -orient vertical -command ::W
	scale .left.wc -variable ::WC -from -20 -to 20 -resolution 0.01 -orient vertical -command ::W

	pack .left.wa -side left -expand 1 -fill both
	pack .left.wb -side left -expand 1 -fill both
	pack .left.wc -side left -expand 1 -fill both
    }
    shutdown {
	unset ::WA ::WB ::WC
    }
}
