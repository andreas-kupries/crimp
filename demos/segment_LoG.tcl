def op_segment_gauss_laplacian_luma {
    label {Segmentation: Laplacian of Gaussian Luma}
    setup {
	variable sigma 3.5
	variable map [list \
			  [binary format ff 0.0 0.0] \
			  [binary format cucu 0 255]]

	proc show {thesigma} {
	    variable L
	    variable M
	    variable map
	    if {![info exists L]} return
	    set overlay [crimp morph igradient \
			     [crimp::map_2grey8_float \
				  [crimp::gaussian_laplacian_float \
				       $L $thesigma] \
				  $map]]
	    set display [crimp alpha opaque \
			     [crimp alpha over \
				  [crimp alpha set \
				       [crimp blank rgb \
					    {*}[crimp dimensions $L] \
					    255 0 0] \
				       $overlay] \
				  $M]]
	    show_image $display
	    return
	}

	proc showit {} {
	    variable sigma
	    show $sigma
	    return
	}

	scale .left.s -variable ::DEMO::sigma \
	    -from 0.5 -to 15 -resolution 0.1 -length 450 \
	    -orient vertical \
	    -command ::DEMO::show

	grid .left.s -row 0 -column 0 -sticky swen
    }
    setup_image {
	variable L [crimp convert 2float [crimp convert 2grey8 [base]]]
	variable M [crimp convert 2rgb [crimp convert 2grey8 [base]]]
	showit
    }
}
