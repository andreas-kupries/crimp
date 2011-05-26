def op_magnifier {
    label Magnifier
    setup_image {
	set G [base]
	show_image $G
    }
    shutdown {
	.c delete magnifier
	crosshair::off .c
    }
    setup {
	set G {}
	set K [crimp kernel make {{0 1 1}} 1]

	package require crosshair
	crosshair::crosshair .c
	crosshair::track on .c ::DEMO::track

	set mx 0
	set my 0

	.c create image [list $mx $my] -anchor center -tags magnifier
	.c itemconfigure magnifier -image [image create photo]

	proc track {_ x y xl yt xr yb} {
	    variable G
	    variable K
	    variable mx
	    variable my

	    if {$G eq {}} return

	    set x [expr {int($x)}]
	    set y [expr {int($y)}]

	    # TODO? Put into text-item placed on top or beside (north)
	    # the magnifier image overlay.
	    log "@ $x $y"

	    set px $x
	    set py $y

	    # =============================================

	    # NOTE: The code below doesn't work for images smaller
	    # than 20 pixels in either dimension.
	    incr x -10 ; if {$x < 0} { set x 0 }
	    incr y -10 ; if {$y < 0} { set y 0 }

	    if {($x + 20) > [crimp width $G]} {
		set x [expr {[crimp width $G] - 20}]
	    }
	    if {($y + 20) > [crimp height $G]} {
		set y [expr {[crimp height $G] - 20}]
	    }

	    # XXX : Maybe change 'cut' to simply put black into areas
	    # outside of the input image ?
	    # XXX: Alternate: Reduce cut area at borders and then use
	    # expand to fill the missing pieces with black.

	    set roi [crimp cut $G $x $y 20 20]

	    #puts R[crimp type $roi]

	    # Expand each pixel into a 8x8 block(2*2*2)
	    set roi [crimp interpolate xy \
			 [crimp interpolate xy \
			      [crimp interpolate xy $roi \
				   2 $K] \
			      2 $K] \
			 2 $K]

	    #puts '[crimp type $roi]

	    crimp write 2tk [.c itemcget magnifier -image] $roi

	    # Move the magnifier on top of the crosshair.
	    set dx [expr {$px - $mx}]
	    set dy [expr {$py - $my}]

	    .c move magnifier $dx $dy
	    set mx $px
	    set my $py
	}
    }
}
