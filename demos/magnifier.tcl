def op_magnifier {
    label Magnifier
    setup_image {
	show_image [base]
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

	proc get {i x y r} {
	    # At x,y, block of radius r.

	    set w $r ; incr w $r
	    set h $r ; incr h $r

	    incr x -$r
	    incr y -$r

	    # Now the block is explicity specified as rectangle with
	    # top-left corner at x,y and width, height.

	    # This may be outside of the image borders. We now shrink
	    # the rectangle to fit the borders, and record this as
	    # expansion to be done after extraction.

	    set l 0 ; set r 0 ; set t 0 ; set b 0

	    set iw [crimp width  $i]
	    set ih [crimp height $i]

	    # Completely outside.
	    if {($x > $iw) ||
		($y > $ih) ||
		(($x+$w) < 0) ||
		(($y+$h) < 0)} {
		return [crimp blank [crimp::TypeOf $i] $w $h 0 0 0]
	    }

	    # At least partially inside.
	    if {$x < 0} {
		set  l [expr {- $x}]
		incr w $x
		set  x 0
	    }
	    if {$y < 0} {
		set  t [expr {- $y}]
		incr h $y
		set  y 0
	    }

	    if {($x+$w) >= $iw} {
		set  r [expr {($x+$w) - $iw}]
		incr w -$r
	    }
	    if {($y+$h) >= $ih} {
		set  b [expr {($y+$h) - $ih}]
		incr w -$b
	    }

	    #puts "$x,$y ${w}x$h in ${iw}x${ih}"

	    # Cut (possibly shrunken) region
	    set roi [crimp cut $i $x $y $w $h]

	    # Expand to full size, using black outside of the input.
	    set roi [crimp expand const $roi $l $t $r $b 0 0 0]

	    return $roi
	}

	proc magnify {z i} {
	    variable K
	    while {$z > 0} {
		set i [crimp interpolate xy $i 2 $K]
		incr z -1
	    }
	    return $i
	}

	proc track {_ x y xl yt xr yb} {
	    variable K
	    variable mx
	    variable my

	    if {[base] eq {}} return

	    set x [expr {int($x)}]
	    set y [expr {int($y)}]

	    # TODO? Put into text-item placed on top or beside (north)
	    # the magnifier image overlay.
	    log "@ $x $y"

	    set px $x
	    set py $y

	    # =============================================
	    # each magnification step is 2x. 3 thus 8x

	    crimp write 2tk [.c itemcget magnifier -image] \
		[magnify 3 [get [base] $x $y 16]]

	    # Move the magnifier on top of the crosshair.
	    set dx [expr {$px - $mx}]
	    set dy [expr {$py - $my}]

	    .c move magnifier $dx $dy
	    set mx $px
	    set my $py
	}
    }
}
