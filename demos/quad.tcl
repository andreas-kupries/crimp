def op_quadrilateral {
    label {Quad mapping}
    active { expr { [bases] == 0} }
    setup {
	proc p {label i} {
	    set t [crimp write 2string pfm-plain $i]
	    set pv [lassign $t _ w h]

	    log* "$label = ${w}x$h \{"
	    set n 0
	    foreach v $pv {
		if {!$n} { log* "\n\t" } else { log* " " }
		log* "$v"
		incr n ; if {$n == $w} { set n 0 }
	    }
	    log "\n\}"
	}

	proc P {label t p} {
	    lassign $p x y
	    set pm [crimp read tcl double [list [list $x 0 0] [list $y 0 0] {1 0 0}]]
	    set d [crimp flip transpose [crimp crop [::crimp::matmul3x3_double $t $pm] 0 0 2 0]]

	    lassign [lrange [crimp write 2string pfm-plain $d] 3 end] xd yd w
	    set x [expr {$xd/double($w)}]
	    set y [expr {$yd/double($w)}]

	    log "$label $p = ($x, $y) \[$xd,$yd,$w\]"
	    return
	}

	proc pmap {src dst t} {
	    foreach sp $src dp $dst l {p1 p2 p3 p4} {
		P "MAP $l ($dp)" [lindex $t 1] $sp
	    }
	    return
	}

	set src {{10 10} {20 5} {20 25} {10 20}}
	set dst {{5 10} {20 5} {20 25} {10 25}}
	set unit {{0 0} {1 0} {1 1} {0 1}}

	set t [::crimp::transform::invert [::crimp::transform::Q2UNIT $src]]
	set s [::crimp::transform::Q2UNIT $dst]
	set w [::crimp::transform::chain $s $t]

	log "src  = $src"
	log "dst  = $dst"
	log "unit = $unit"

	log "\nsrc --> unit rectangle"
	p T [lindex $t 1]
	pmap $src $unit $t

	log "\nunit rectangle --> dst"
	p S [lindex $s 1]
	pmap $unit $dst $s

	log "\nsrc --> dst"
	p Q [lindex $w 1]
	pmap $src $dst  $w
    }
}
