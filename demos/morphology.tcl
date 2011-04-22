def op_morphology {
    label {Morphology Operations}
    setup {
	variable lastop none
	variable n 0

	proc do {op} {
	    variable lastop $op

	    if {[string match !* $op]} {
		set invert 1
		set op [string range $op 1 end]
	    } else {
		set invert 0
	    }

	    if {$op eq "none"} {
		set image [base]
	    } else {
		set image [crimp alpha opaque [crimp morph $op [base]]]
	    }
	    if {$invert} {
		set image [crimp invert $image]
	    }

	    show_image $image
	}

	proc action {op} {
	    variable n

	    if {[string match !* $op]} {
		set label "invert ([string range $op 1 end])"
	    } else {
		set label $op
	    }

	    button .left.[incr n] \
		-text $label \
		-command [list [namespace current]::do $op] \
		-anchor w
	    grid .left.$n -row $n -column 0 -sticky swen
	    return
	}

	action none

	action erode
	action dilate
	action open
	action close
	action gradient
	action igradient
	action egradient
	action tophatw
	action tophatb
	action toggle

	action !erode
	action !dilate
	action !open
	action !close
	action !gradient
	action !igradient
	action !egradient
	action !tophatw
	action !tophatb
	action !toggle
    }
    setup_image {
	do $lastop
    }
}
