def effect_wavy {
    label Wavy
    setup {
	proc show {args} {
	    variable wa
	    variable wb
	    variable wc
	    show_image [crimp wavy [base] $wa $wb $wc]
	    return
	}

	variable wa 1
	variable wb 1
	variable wc 1

	scale .left.wa -variable ::DEMO::wa -from -20 -to 20 -resolution 0.01 -orient vertical -command ::DEMO::show
	scale .left.wb -variable ::DEMO::wb -from -20 -to 20 -resolution 0.01 -orient vertical -command ::DEMO::show
	scale .left.wc -variable ::DEMO::wc -from -20 -to 20 -resolution 0.01 -orient vertical -command ::DEMO::show

	pack .left.wa -side left -expand 1 -fill both
	pack .left.wb -side left -expand 1 -fill both
	pack .left.wc -side left -expand 1 -fill both
    }
    setup_image { show }
}
