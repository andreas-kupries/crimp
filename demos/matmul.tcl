def op_3x3multiplication {
    label {3x3 Matrix Multiplication}
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

	set I [crimp read tcl float {
	    {1 0 0}
	    {0 1 0}
	    {0 0 1}
	}]
	set T [crimp read tcl float {
	    {0 0 1}
	    {0 1 0}
	    {1 0 0}
	}]
	set X [crimp read tcl float {
	    {0 3 0}
	    {2 0 4}
	    {0 5 0}
	}]

	p I*T=T [crimp::matmul3x3_float $I $T]
	p T*I=T [crimp::matmul3x3_float $T $I]

	p I*X=X [crimp::matmul3x3_float $I $X]
	p X*I=X [crimp::matmul3x3_float $X $I]

	p T*X=? [crimp::matmul3x3_float $T $X]
	p X*T=? [crimp::matmul3x3_float $X $T]
    }
}
