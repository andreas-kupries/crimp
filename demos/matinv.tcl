def op_3x3inverse {
    label {3x3 Matrix Inverse}
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

	set X [crimp read tcl float {
	    {1 3 0}
	    {2 1 4}
	    {0 5 1}
	}]
	set Xinv [crimp::matinv3x3_float $X]

	p X        $X
	p Xinv     $Xinv
	p X*Xinv=I [crimp::matmul3x3_float $X $Xinv] 
	p Xinv*X=I [crimp::matmul3x3_float $Xinv $X] 

	set I [crimp read tcl float {
	    {1 0 0}
	    {0 1 0}
	    {0 0 1}
	}]

	p Iinv=I [crimp::matinv3x3_float $I]

	set T [crimp read tcl float {
	    {1 0 5}
	    {0 1 2}
	    {0 0 1}
	}]

	p T    $T
	p Tinv [crimp::matinv3x3_float $T]
    }
}
