def op_rof_median_luma {
    label {Median Filter (Luma)}
    setup_image {

	# Create series of median-filtered images on the luma of the
	# base, with different kernel radii.

	variable images
	set images {}

	set luma [crimp convert 2grey8 [base]]
	lappend images $luma
	lappend images [crimp rankfilter $luma]
	lappend images [crimp rankfilter $luma 10]
	lappend images [crimp rankfilter $luma 20]

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
