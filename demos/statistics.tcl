def op_statistics {
    label Statistics
    setup_image {
	variable stat
	variable hist
	array set stat [crimp statistics [base]]

	foreach k [lsort -dict [array names stat]] {
	    if {[string match {channel *} $k]} {
		array set hist $stat($k)
		log "$k"
		foreach j [lsort -dict [array names hist]] {
		    log "\t$j = $hist($j)"
		}
	    } else {
		log "$k = $stat($k)"
	    }
	}
    }
}
