def op_statistics {
    label Statistics
    setup_image {
	variable stat
	variable hist
	array set stat [crimp statistics basic [base]]

	foreach k [lsort -dict [array names stat]] {
	    if {$k eq "channel"} {
		log "$k"
		foreach {c cdata} $stat($k) {
		    log "\t$c"
		    array set hist $cdata
		    foreach j [lsort -dict [array names hist]] {
			log "\t\t$j = $hist($j)"
		    }
		}
	    } else {
		log "$k = $stat($k)"
	    }
	}
    }
}
