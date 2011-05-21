def op_euclidean_distance {
    label {Euclidean Distance}
    setup {
	variable values {1e30 0.0}
	proc show {} {
	    variable L
	    variable values
	    if {![info exists L]} return
	    set ind [crimp::indicator_grey8_float $L 0 {*}$values]
	    set map [crimp::sqrt_float \
			 [crimp::euclidean_distance_map_float $ind]]
	    show_image [crimp::FITFLOAT $map]
	    return
	}
	radiobutton .left.bg -variable ::DEMO::values -value {1e30 0.0} \
	    -text "Background" -command ::DEMO::show
	radiobutton .left.fg -variable ::DEMO::values -value {0.0 1e30} \
	    -text "Foreground" -command ::DEMO::show
	grid .left.bg -row 0 -column 0 -sticky w
	grid .left.fg -row 1 -column 0 -sticky w
    }
    setup_image {
	variable L [crimp convert 2grey8 [base]]
	show
    }
}
