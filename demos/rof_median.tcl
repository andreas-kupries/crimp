def op_rof_median {
    label {Median Filter}
    setup_image {

	# Create series of median-filtered images from the base, with
	# different kernel radii.

	variable images
	set images {}
	lappend images [base]
	lappend images [crimp rankfilter [base]]
	lappend images [crimp rankfilter [base] 10]
	lappend images [crimp rankfilter [base] 20]

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
