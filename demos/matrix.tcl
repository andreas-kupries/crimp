def effect_matrix {
    label RotMatrix
    setup {
	variable angle 0

	proc show {theangle} {
	    set s [expr {sin($theangle * 0.017453292519943295769236907684886)}]
	    set c [expr {cos($theangle * 0.017453292519943295769236907684886)}]
	    set matrix [list \
			    [list $c           $s 0] \
			    [list [expr {-$s}] $c 0] \
			    [list $s           $s 1]]
	    show_image [crimp matrix [base] $matrix]
	    return
	}

	proc showit {} {
	    variable angle
	    show $angle
	    return
	}

	scale .left.s -variable ::DEMO::angle \
	    -from -180 -to 180 -resolution 0.01 \
	    -orient vertical \
	    -command ::DEMO::show

	pack .left.s -side left -fill both -expand 1
    }
    setup_image {
	showit
    }
}
