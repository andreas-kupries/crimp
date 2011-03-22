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

	set i [crimp blank float 5 5  2]
	set s [crimp integrate $i]

	# radius = 1 => 3x3, 2-border for (radius+1)
	set e  [crimp expand mirror $i 2 2 2 2]
	set se [crimp integrate $e]
	set r  [crimp::region_sum $se 1]
	set m1 [crimp::scale_float $r [expr {1./9}]]
	# m1 = 1st-order momentum = mean

	set sq  [crimp multiply $e $e]
	set ssq [crimp integrate $sq]
	set rsq [crimp::region_sum $ssq 1]
	set m2  [crimp::scale_float $rsq [expr {1./9}]]
	set var [crimp subtract $m2 [crimp multiply $m1 $m1]]
	set std [crimp::sqrt_float $var]
	# m1 = 2nd-order momentum = variance

	p I      $i
	p S      $s
	p E      $e
	p SUM    $se
	p SUM/3  $r
	p M1/3   $m1

	p E^2     $sq
	p SUM/E^2 $ssq
	p SUM3/E2 $rsq
	p M2/3    $m2
	p VAR/3   $var
	p STD/3   $std
    }
}
