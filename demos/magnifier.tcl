def op_magnifier {
    label Magnifier
    setup_image {
	show_image [base]
	replay
    }
    shutdown {
	.c delete magnifier
	crosshair::off .c
    }
    setup {
	set K [crimp kernel make {{0 1 1}} 1]

	set settings {
	    {1 64}
	    {2 32}
	    {3 16}
	    {4  8}
	    {5  4}
	    {6  2}
	    {0  0}
	}

	set current {0 0}

	package require crosshair
	crosshair::crosshair .c
	crosshair::track on .c ::DEMO::track
	bind .c <3> ::DEMO::next
	bind .c <1> {::DEMO::next -1}

	set mx 0
	set my 0

	set tx 0
	set ty 0

	.c create image [list $mx $my] -anchor center -tags magnifier
	.c itemconfigure magnifier -image [image create photo]

	proc next {{dir 1}} {
	    variable current
	    variable settings

	    # current is at the end of settings, always.

	    if {$dir > 0} {
		set current  [lindex $settings 0]
		set settings [linsert [lrange $settings 1 end] end $current]
	    } else {
		# end-1, because end is current.
		set old $current
		set current  [lindex $settings end-1]
		set settings [linsert [lrange $settings 0 end-1] 0 $old]
	    }

	    log "zoom $current | $settings"
	    replay
	    return
	}

	proc get {i x y r} {
	    # At x,y, block of radius r.

	    #set trace {}
	    #lappend trace "@ $x $y r$r"

	    set w $r ; incr w $r
	    set h $r ; incr h $r

	    incr x -$r
	    incr y -$r

	    #lappend trace "rect $x $y ($w $h) [expr {$x+$w-1}] [expr {$y+$h-1}]"

	    # Now the block is explicity specified as rectangle with
	    # top-left corner at x,y and width, height.

	    # This may be outside of the image borders. We now shrink
	    # the rectangle to fit the borders, and record this as
	    # expansion to be done after extraction.

	    set l 0 ; set r 0 ; set t 0 ; set b 0

	    set iw [crimp width  $i]
	    set ih [crimp height $i]

	    #lappend trace "versus $iw $ih"

	    # Completely outside.
	    if {($x >= $iw) ||
		($y >= $ih) ||
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
		incr h -$b
	    }

	    #lappend trace "blanks $l > ... < $r / $t V ... ^ $b"
	    #lappend trace "cut $x,$y ${w}x$h in ${iw}x${ih}"

	    #if {$w < 0} { puts [join $trace \n] ; exit }
	    #if {$h < 0} { puts [join $trace \n] ; exit }

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
	    variable current
	    variable K
	    variable mx
	    variable my
	    variable tx
	    variable ty

	    set x [expr {int($x)}]
	    set y [expr {int($y)}]

	    lassign $current scale radius

	    .c lower magnifier

	    # Remember last track position, for replay. Having this
	    # separate from the magnifier location ensures that it
	    # gets properly moved on replay, should it be necessary.

	    set tx $x
	    set ty $y

	    # (b) Do nothing without image or magnification disabled.
	    if {([base] eq {}) ||
		($scale  == 0) ||
		($radius == 0)} {
		return
	    }

	    # (a) Move the magnifier on top of the crosshair.
	    set dx [expr {$x - $mx}]
	    set dy [expr {$y - $my}]

	    if {$dx || $dy} {
		.c move magnifier $dx $dy
		set mx $x
		set my $y
	    }

	    # TODO? Put into text-item placed on top or beside (north)
	    # the magnifier image overlay.
	    set d [expr {2*$radius}]
	    log "@ $x $y $scale $radius => [expr {2**$scale}]x\[${d}x${d}\]"

	    # =============================================

	    crimp write 2tk [.c itemcget magnifier -image] \
		[magnify $scale [get [base] $x $y $radius]]

	    .c raise magnifier
	    return
	}

	proc replay {} {
	    variable tx
	    variable ty
	    track _ $tx $ty _ _ _ _
	}
    }
}
