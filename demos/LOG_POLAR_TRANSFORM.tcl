def op_Log_Polar {
    label {Log Polar Transform }
    setup_image {
	show
    }
    setup {
	variable hcentre  0
	variable vcentre  0 
	variable corner   1

	proc show {args} {
	    variable hcentre  
	    variable vcentre   
	    variable corner   	    

	    set L [base]
	    show_image [crimp logpolar $L \
			    {*}[::crimp::dimensions $L] \
			    $hcentre $vcentre $corner]
	    return
	}

	scale .left.hcentre -variable ::DEMO::hcentre \
	    -from -200 -to 200 -resolution 10 -length 200 \
	    -orient vertical \
	    -command ::DEMO::show

	scale .left.vcentre -variable ::DEMO::vcentre \
	    -from -200 -to 200 -resolution 10 -length 200 \
	    -orient vertical \
	    -command ::DEMO::show

	checkbutton .left.corner -variable ::DEMO::corner \
	    -text Corners -command ::DEMO::show

	grid .left.corner  -row 0 -column 0 -sticky swen -columnspan 2
	grid .left.hcentre -row 1 -column 0 -sticky swen
	grid .left.vcentre -row 1 -column 1 -sticky swen
    }
}
