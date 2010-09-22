def effect_rehsv {
    label {Change HSV}
    setup {
	variable hsvbase
	variable mask

	variable ghg 1 ; variable gsg 1 ; variable gvg 1
	variable ghb 0 ; variable gsb 0 ; variable gvb 0

	variable th [crimp table linear -wrap -- $ghg $ghb] ; variable mh [crimp map linear -wrap -- $ghg $ghb]
	variable ts [crimp table linear       -- $gsg $gsb] ; variable ms [crimp map linear       -- $gsg $gsb]
	variable tv [crimp table linear       -- $gvg $gvb] ; variable mv [crimp map linear       -- $gvg $gvb]

	proc H {args} {
	    variable ghb
	    variable ghg
	    variable th [crimp table linear -wrap $ghg $ghb]
	    variable mh [crimp map   linear -wrap $ghg $ghb]
	    UPDATE
	    return
	}
	proc S {args} {
	    variable gsb
	    variable gsg
	    variable ts [crimp table linear -- $gsg $gsb]
	    variable ms [crimp map   linear -- $gsg $gsb]
	    UPDATE
	    return
	}
	proc V {args} {
	    variable gvb
	    variable gvg
	    variable tv [crimp table linear -- $gvg $gvb]
	    variable mv [crimp map   linear -- $gvg $gvb]
	    UPDATE
	    return
	}
	proc UPDATE {} {
	    variable mh
	    variable ms
	    variable mv
	    variable hsvbase
	    variable mask
	    if {![info exists hsvbase]} return

	    show_image [crimp alpha set \
			    [crimp convert 2rgb [crimp remap $hsvbase $mh $ms $mv]] \
			    $mask]
	    return
	}

	scale .left.hg -variable ::DEMO::ghg -from -10 -to 10  -resolution 0.01 -orient vertical -command ::DEMO::H
	scale .left.sg -variable ::DEMO::gsg -from -10 -to 10  -resolution 0.01 -orient vertical -command ::DEMO::S
	scale .left.vg -variable ::DEMO::gvg -from -10 -to 10  -resolution 0.01 -orient vertical -command ::DEMO::V

	scale .left.hb -variable ::DEMO::ghb -from 0 -to 255 -resolution 1    -orient vertical -command ::DEMO::H
	scale .left.sb -variable ::DEMO::gsb -from 0 -to 255 -resolution 1    -orient vertical -command ::DEMO::S
	scale .left.vb -variable ::DEMO::gvb -from 0 -to 255 -resolution 1    -orient vertical -command ::DEMO::V

	plot  .left.ph -variable ::DEMO::th -title Hue
	plot  .left.ps -variable ::DEMO::ts -title Saturation
	plot  .left.pv -variable ::DEMO::tv -title Value

	grid .left.hg -row 0 -column 0 -sticky sen
	grid .left.ph -row 0 -column 1 -sticky swen
	grid .left.hb -row 0 -column 2 -sticky sen

	grid .left.sg -row 1 -column 0 -sticky sen
	grid .left.ps -row 1 -column 1 -sticky swen
	grid .left.sb -row 1 -column 2 -sticky sen

	grid .left.vg -row 2 -column 0 -sticky sen
	grid .left.pv -row 2 -column 1 -sticky swen
	grid .left.vb -row 2 -column 2 -sticky sen
    }
    setup_image {
	variable hsvbase [crimp convert 2hsv [base]]
	variable mask    [lindex [crimp split [base]] end]
	UPDATE
    }
}
