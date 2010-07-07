def op_gamma {
    label Gamma
    setup {
	set ::GAMMA 1
	scale .g \
	    -variable ::GAMMA \
	    -from 0 \
	    -to 5 \
	    -resolution 0.01 \
	    -orient vertical \
	    -command [list ::apply {{gamma} {
		show_image [crimp gamma [base] $gamma]
	    }}]
	extendgui .g
    }
    shutdown {
	destroy .g
	unset ::GAMMA
    }
}
