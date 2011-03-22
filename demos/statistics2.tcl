def op_statistics_float {
    label {Statistics/Float}
    active { expr { [bases] == 0} }
    setup {
	set X [crimp read tcl float {
	    {1 3 0}
	    {2 1 4}
	    {0 5 1}
	}]

	array set stat [crimp::stats_float $X]
	array set stat $stat(value)
	unset stat(value)

	foreach k [lsort -dict [array names stat]] {
	    log "$k = $stat($k)"
	}
    }
}
