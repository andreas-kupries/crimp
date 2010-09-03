def op_blend_pyramid {
    label {Blend Pyramid}
    active {
	expr {
	      ([bases] == 2) &&
	      ([crimp dimensions [base 0]] eq [crimp dimensions [base 1]])
	  }
    }
    setup {
	# Define the interpolation kernel for moving up in the chain
	# of results.
	variable ki [crimp kernel make {{1 4 6 4 1}} 8]
    }
    setup_image {

	# Get the images to blend.
	variable left  [base 0]
	variable right [base 1]

	# Compute a simple blending mask.
	variable w
	variable h
	lassign [crimp dimensions [base 0]] w h
	set w [expr {$w/2}]
	variable mask [crimp montage horizontal \
			   [crimp blank grey8 $w $h 255] \
			   [crimp blank grey8 $w $h 0]]

	# Depth of the pyramids. Restricted by the number of proper 2x
	# decimations we can do on the 800x600 images.
	variable depth 3

	# Compute the input pyramids. We drop the unmodified originals.
	# Note that the mask is a gauss pyramid => successive blurring.
	variable pleft  [lrange [crimp pyramid laplace $left  $depth] 1 end]
	variable pright [lrange [crimp pyramid laplace $right $depth] 1 end]
	variable pmask  [crimp pyramid gauss   $mask  $depth]

	# Merge the input pyramids into a blend result pyramid.
	variable pblend {}
	foreach a $pleft b $pright m $pmask {
	    #puts "B wXh = [crimp dimensions $a]|[crimp dimensions $b]|[crimp dimensions $m]"
	    lappend pblend [crimp add \
			    [crimp multiply $a $m] \
			    [crimp multiply $b [crimp invert $m]]]
	}

	# At last, fold the pyramid back into a single image, from the
	# bottom up, interpolating the intermediate results to match
	# the next level.

	variable result [lindex $pblend end]
	foreach dog [lreverse [lrange $pblend 0 end-1]] {
	    #puts "+ wXh = [crimp dimensions $dog]|[crimp dimensions $result]"
	    set result [crimp add $dog [crimp interpolate $result 2 $ki]]
	}

	show_image $result
	return

	# Slideshow of inputs and intermediate results for debugging...
	variable slides {}
	lappend  slides $left $right $mask
	foreach i [list {*}$pleft {*}$pright] {
	    lappend slides [crimp alpha opaque $i]
	}
	lappend slides {*}$pmask
	foreach i $pblend {
	    lappend slides [crimp alpha opaque $i]
	}
	lappend slides [crimp alpha opaque $result]
	show_slides $slides
    }
}
