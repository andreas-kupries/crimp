def op_solarize {
    label Solarize
    setup {
	set ::THRESHOLD  256
	set ::TABLE {}

	plot  .left.p -variable ::TABLE
	scale .left.s -variable ::THRESHOLD \
	    -from 0 -to 256 \
	    -orient horizontal \
	    -command [list ::apply {{threshold} {
		set ::TABLE [crimp table solarize  $threshold]
		show_image  [crimp solarize [base] $threshold]
	    }}]

	grid .left.s -row 0 -column 0 -sticky swen
	grid .left.p -row 1 -column 0 -sticky swen
    }
    shutdown {
	unset ::THRESHOLD ::TABLE
    }
}
