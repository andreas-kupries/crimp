def op_pyramid_laplace2 {
    label {Laplace pyramid (normalized)}
    setup_image {
	# Create a laplacian image pyramid, aka difference of
	# gaussians. The results are scaled back to the original
	# before cycling.

	variable images
	set images {}
	foreach \
	    i [crimp pyramid laplace [base] 6] \
	    s {1 1 2 4 8 16 32 64} {
	    set i [norm $i $s]
	    lappend images [crimp setalpha $i [crimp blank grey8 {*}[crimp dimensions $i] 255]]
	}
    }
    setup {
	variable token

	proc norm {image fac} {
	    if {$fac == 1} { return $image }
	    set kernel [crimp kernel make {{1 4 6 4 1}} 8]
	    while {$fac > 1} {
		set image [crimp interpolate $image 2 $kernel]
		set fac [expr {$fac/2}]
	    }
	    return $image
	}

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
