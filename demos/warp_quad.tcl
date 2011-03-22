def effect_warp_quad_rgba {
    label {Warp/BiL rgba (Quadrilaterals)}
    setup {
	proc show {} {
	    set src {{10 10} {200 5} {200 250} {10 200}}
	    set dst  {{0  0} {200 5} {150 400} {50 250}}

	    set t [crimp transform quadrilateral $src $dst]

	    log "\nsrc --> dst"
	    p T [lindex $t 1]
	    pmap $src $dst $t

	    lassign [crimp dimensions [base]] w h
	    log "\nCorners"
	    pmap "{0 0} {$w 0} {$w $h} {0 $h}" {? ? ? ?} $t

	    show_image [crimp warp projective -interpolate bilinear [base] $t]
	    return
	}

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
	    set pm [crimp read tcl float [list [list $x 0 0] [list $y 0 0] {1 0 0}]]
	    set d [crimp flip transpose [crimp crop [::crimp::matmul3x3_float $t $pm] 0 0 2 0]]

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

    }
    setup_image {
	show
    }
}
