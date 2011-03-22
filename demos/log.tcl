def op_log {
    label Log-Compression
    setup {
	variable maxvalue 255
	variable table    {}

	proc show {themaxvalue} {
	    variable table [crimp table log    $themaxvalue]
	    show_image     [crimp remap [base] [crimp mapof $table]]
	    return
	}

	proc showit {} {
	    variable maxvalue
	    show $maxvalue
	    return
	}

	plot  .left.p -variable ::DEMO::table -title Maxvalue
	scale .left.s -variable ::DEMO::maxvalue \
	    -from 1 -to 255 \
	    -orient horizontal \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
	grid .left.p -row 1 -column 0 -sticky swen
    }
    setup_image {
	showit
    }
}
