def degamma {
    label Degamma
    setup {
	set ::DEGAMMA 1
	scale .g \
	    -variable ::DEGAMMA \
	    -from 0.01 \
	    -to   5.00 \
	    -resolution 0.01 \
	    -orient vertical \
	    -command [list ::apply {{gamma} {
		show_image [crimp degamma [base] $gamma]
	    }}]
	extendgui .g
    }
    shutdown {
	destroy .g
	unset ::DEGAMMA
    }
}
