def op_pyramid_gauss2 {
    label {Gauss pyramid (normalized)}
    setup_image {

	# Create an image pyramid, and then scale the result back up
	# to match the original one before cycling.

	proc norm {image fac} {
	    if {$fac == 1} { return $image }
	    set kernel [crimp kernel make {{1 4 6 4 1}} 8]
	    while {$fac > 1} {
		set image [crimp interpolate $image 2 $kernel]
		set fac [expr {$fac/2}]
	    }
	    return $image
	}

	variable images
	variable scales

	set images [crimp pyramid gauss [base] 6]
	set scales {1 2 4 8 16 32 64}

	set r {}
	foreach i $images s $scales {
	    lappend r [norm $i $s]
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
