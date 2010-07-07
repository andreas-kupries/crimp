def op_solarize {
    label Solarize
    setup {
	set ::X 256
	scale .s \
	    -variable ::X \
	    -from 0 \
	    -to 256 \
	    -orient vertical \
	    -command [list ::apply {{threshold} {
		show_image [crimp solarize [base] $threshold]
	    }}]
	extendgui .s
    }
    shutdown {
	destroy .s
	unset ::X
    }
}
