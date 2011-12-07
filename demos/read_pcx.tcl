def read_pcx {
    label {Read (PCX), selected}
    active {
	expr {[bases] == 0}
    }
    setup {
	set K [crimp kernel make {{0 1 1}} 1]

	proc 8x {image} {
	    variable K
	    return [crimp interpolate xy \
			[crimp interpolate xy \
			     [crimp interpolate xy $image 2 $K] 2 $K] 2 $K]
	}

	proc SHOW {path label} {
	    if {[catch {
		set pcx [crimp read pcx [fileutil::cat -translation binary $path]]
	    } msg]} {
		log ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		log PCX\t:$path\t([file size $path])
		log $msg error
		log ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		return
	    }
	    show_image $pcx
	}

	::apply {{images} {
	    set r 0
	    foreach i $images {
		set ix [file rootname [file tail $i]]
		set b .left.$ix
		ttk::button $b \
		    -text $ix \
		    -command [list ::DEMO::SHOW $i $ix]
		grid $b -row $r -column 0 -sticky swen
		incr r
	    }
	}} [lsort -dict [glob -directory [appdir]/images/pcx *.pcx]]
    }
}
