def op_solarize {
    label Solarize
    setup {
	variable threshold 256
	variable table     {}

	plot  .left.p -variable ::DEMO::table -title Threshold
	scale .left.s -variable ::DEMO::threshold \
	    -from 0 -to 256 \
	    -orient horizontal \
	    -command [list ::apply {{thethreshold} {
		variable table [crimp table solarize  $thethreshold]
		show_image     [crimp solarize [base] $thethreshold]
	    } ::DEMO}]

	grid .left.s -row 0 -column 0 -sticky swen
	grid .left.p -row 1 -column 0 -sticky swen
    }
}
