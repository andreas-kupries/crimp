def op_pyramid_blend {
    label {Blend Pyramid}
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup_image {
	variable ki [crimp kernel make {{1 4 6 4 1}} 8]
	variable w
	variable h
	lassign [crimp dimensions [base 0]] w h
	set w [expr {$w/2}]
	variable mask [crimp montage horizontal \
			   [crimp blank grey8 $w $h 0] \
			   [crimp blank grey8 $w $h 255]]
	variable depth 3

#set mx [crimp pyramid laplace $mask    $depth]
#puts "$depth | [llength $mx]"
#foreach x $mx { puts \t[crimp dimensions $x] }

	variable ap [lrange [crimp pyramid laplace [base 0] $depth] 1 end]
	variable bp [lrange [crimp pyramid laplace [base 1] $depth] 1 end]
	variable mp [lrange [crimp pyramid laplace $mask    $depth] 1 end]

	variable rp {}
	foreach a $ap b $bp m $mp {
	    puts "B wXh = [crimp dimensions $a]|[crimp dimensions $b]|[crimp dimensions $m]"

	    lappend rp [crimp add \
			    [crimp multiply $a $m] \
			    [crimp multiply $b [crimp invert $m]]]
	}

	# rp = b1 b2 ... bN gauss

	variable result [lindex $rp end] ;# gaussian
	foreach dog [lreverse [lrange $rp 0 end-1]] {
	    puts "+ wXh = [crimp dimensions $dog]|[crimp dimensions $result]"
	    set result [crimp add $dog [crimp interpolate $result 2 $ki]]
	}

	show_image $result
    }
}
