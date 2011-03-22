def op_threshold_global {
    label "Threshold Global"
    setup {
	# Demo various ways of for the automatic calculation of a
	# global threshold.

	proc showbase {} {
	    show_image [base]
	    return
	}

	proc average {} {
	    show_image [crimp threshold global mean [base]]
	    return
	}

	proc median {} {
	    show_image [crimp threshold global median [base]]
	    return
	}

	proc middle {} {
	    show_image [crimp threshold global middle [base]]
	    return
	}

	proc kmeans {} {
	    # TODO
	    set pixels [lsort -uniq [lrange [crimp write 2string pgm-plain [crimp convert 2grey8 [base]]] 5 end]]

	    log "pixels = [llength $pixels]"

	    lassign [km {0 255} $pixels ::DEMO::1dd ::DEMO::1dm] \
		_ plow _ pup

	    # compute upper/lower borders of the lower/upper
	    # partitions.
	    set up  [tcl::mathfunc::max {*}$plow]
	    set low [tcl::mathfunc::min {*}$pup]

	    log "...$up) ... ($low..."

	    if {$up > $low} {
		log "error, border order violation ($up > $low)"
	    }

	    # Put threshold between the borders, in the middle.
	    set t [expr {int (0.5*($up + $low))}]

	    log ".........^ $t"

	    show_image [crimp threshold global below [base] $t]
	    return
	}

	# 1d distance and mean
	proc 1dd {a b} { expr {abs($a - $b)} }
	proc 1dm {set} { expr {[tcl::mathop::+ {*}$set]/double([llength $set])} }

	# TODO: Should have k-means algorithm which operates on an
	# histogram of observations, i.e. a value -> count dictionary.

	proc centerof {o centers deltacmd} {
	    set min {}
	    set minc {}
	    foreach c $centers {
		set d [{*}$deltacmd $o $c]
		if {$min eq {} || $d < $min} {
		    set min $d
		    set minc $c
		}
	    }
	    return $minc
	}

	proc dictsort {dict} {
	    array set a $dict
	    set out [list]
	    foreach key [lsort [array names a]] {
		lappend out $key $a($key)
	    }
	    return $out
	}

	proc km {centers observations deltacmd meancmd} {
	    # centers = initial set of cluster centers
	    # observations = the data points to cluster
	    # deltacmd = compute distance between points
	    # compute mean of a set of points.

	    # http://en.wikipedia.org/wiki/K-means_clustering#Standard_algorithm
	    # aka http://en.wikipedia.org/wiki/Lloyd%27s_algorithm
	    # 'Voronoi iteration'

	    set lastmap {}
	    while {1} {
		log "km = | $centers |"
		# I. Assign observations to centers.
		set map {}
		foreach o $observations {
		    dict lappend map [centerof $o $centers $deltacmd] $o
		}

		# Ia. Check for convergence, i.e. no changes between
		#     the previous and current assignments.
		set smap [dictsort $map]
		if {$smap eq $lastmap} {
		    return $map
		}

		# II. Compute new centers from the partitions.
		set new {}
		foreach {c partition} $map {
		    lappend new [{*}$meancmd $partition]
		}

		set centers $new
		set lastmap $smap
	    }
	}

	proc otsu {} {
	    show_image [crimp threshold global otsu [base]]
	    return
	}

	button .left.base   -text Base    -command ::DEMO::showbase
	button .left.middle -text Middle  -command ::DEMO::middle
	button .left.avg    -text Average -command ::DEMO::average
	button .left.med    -text Median  -command ::DEMO::median
	button .left.otsu   -text Otsu    -command ::DEMO::otsu
	button .left.km     -text 2-Means -command ::DEMO::kmeans

	grid .left.base   -row 2 -column 0 -sticky swen
	grid .left.avg    -row 3 -column 0 -sticky swen
	grid .left.med    -row 4 -column 0 -sticky swen
	grid .left.middle -row 5 -column 0 -sticky swen
	grid .left.otsu   -row 6 -column 0 -sticky swen
	grid .left.km     -row 7 -column 0 -sticky swen
    }
    setup_image {
	showbase
    }
}
