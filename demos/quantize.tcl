def op_quantize {
    label Quantize
    setup {
	variable bins  2
	variable where 0
	variable table {}

	scale .left.bins  -variable ::DEMO::bins  -from 2 -to 256 -orient vertical -command ::DEMO::showit
	scale .left.where -variable ::DEMO::where -from 0 -to 100 -orient vertical -command ::DEMO::showit
	plot  .left.p     -variable ::DEMO::table -title Quantization

	plot  .left.h     -variable ::DEMO::hist -locked 0 -title Luma
	plot  .left.hl    -variable ::DEMO::HL   -locked 0 -title {Q Luma}
	plot  .left.tl    -variable ::DEMO::TL   -locked 0 -title {Q CDF Luma}

	grid .left.p     -row 0 -column 0 -sticky swen
	grid .left.h     -row 1 -column 0 -sticky swen
	grid .left.hl    -row 2 -column 0 -sticky swen
	grid .left.tl    -row 3 -column 0 -sticky swen

	grid .left.bins  -row 0 -column 1 -rowspan 4 -sticky swen
	grid .left.where -row 0 -column 2 -rowspan 4 -sticky swen

	proc showit {args} {
	    variable bins
	    variable where
	    show $bins $where
	    return
	}

	proc show {n p} {
	    variable hist
	    variable base
	    variable table [crimp table quantize histogram $n $p $hist]
	    set      map     [crimp map quantize histogram $n $p $hist]
	    set      image [crimp remap $base $map]

	    show_image $image

	    # Quantized luma and cdf
	    variable HL [dict values [dict get [crimp histogram $image] luma]]
	    variable TL [crimp::CUMULATE $HL]
	    return
	}
    }
    setup_image {
	variable base  [crimp convert 2grey8 [base]]
	variable hist  [dict get [crimp histogram $base] luma]
	showit
    }
}
