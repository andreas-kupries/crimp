def op_pyramid_laplace {
    label {Laplace pyramid}
    setup_image {

	# Create a laplacian image pyramid, aka difference of
	# gaussians.

	variable images
	set images [crimp pyramid laplace [base] 3]

	set r {}
	foreach i $images {
	    lappend r [crimp setalpha $i [crimp blank grey8 {*}[crimp dimensions $i] 255]]
	}
	set images $r

	proc cycle {lv} {
	    upvar 1 $lv list
	    set tail [lassign $list head]
	    set list [list {*}$tail $head]
	    return $head
	}
    }
    setup {
	variable token
	proc next {} {
	    variable token
	    set token [after 1000 DEMO::next]

	    variable images
	    if {![info exists images] || ![llength $images]} return

	    show_image [cycle images]
	    return
	}

	next
    }
    shutdown {
	after cancel $token
    }
}
