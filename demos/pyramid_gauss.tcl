def op_pyramid_gauss {
    label {Gauss pyramid}
    setup_image {
	variable images
	set images [crimp pyramid gauss [base] 4]
    }
    setup {
	variable token
	proc next {} {
	    variable token
	    set token [after 100 DEMO::next]

	    variable images
	    if {![llength $images]} return

	    set tail [lassign $images head]
	    set images [list {*}$tail $head]
	    show_image $head
	    return
	}

	next
    }
    shutdown {
	after cancel $token
    }
}
