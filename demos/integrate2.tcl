def op_integrate_fixed {
    label Integrate/Fixed
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

	set i [crimp blank float 5 5  1]
	set s [crimp integrate $i]

	# radius = 1 => 3x3, 2-border for (radius+1)
	set e  [crimp expand mirror $i 2 2 2 2]
	set se [crimp integrate $e]
	set r  [crimp::region_sum $se 1]
	set m  [crimp::scale_float $r [expr {1./9}]]

	p I    $i
	p S    $s
	p E    $e
	p SE/4 $se
	p R/3  $r
	p M/3  $m
    }
}
