def op_pyramid_gauss {
    label {Gauss pyramid}
    setup_image {
	# Create a gaussian image pyramid.

	variable images
	set images [crimp pyramid gauss [base] 4]
    }
    setup {
	variable token

	proc cycle {lv} {
	    upvar 1 $lv list
	    set tail [lassign $list head]
	    set list [list {*}$tail $head]
	    return $head
	}

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
