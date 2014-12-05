#!/bin/sh
# -*- tcl -*-
# The next line restarts with tclsh.\
exec tclsh "$0" ${1+"$@"}

puts "CRIMP demos"

set myargs $argv
set argv {}

if {[catch {
    puts "Trying Tcl/Tk 8.6"

    package require Tcl 8.6
    package require Tk  8.6

    puts "Using  Tcl/Tk 8.6"
}]} {
    puts "Trying Tcl/Tk 8.5 + img::png"

    package require Tcl 8.5
    package require Tk  8.5
    package require img::png

    puts "Using  Tcl/Tk 8.5 + img::png"
}

if {[llength $myargs]} {
    lappend auto_path {*}$myargs
}

package require widget::scrolledwindow
package require widget::toolbar
package require widget::arrowbutton
package require crosshair
package require fileutil

# Self dir
set selfdir [file dirname [file normalize [info script]]]

puts "In $selfdir"

set triedprebuilt 0
if {[catch {
    set triedprebuilt 1

    puts "Trying prebuild packages"

    # Use crimp as prebuilt package
    lappend auto_path $selfdir/lib

    foreach p {
	crimp::core
	crimp
	crimp::tk
	crimp::ppm
	crimp::pgm
	crimp::pfm
	crimp::bmp
	crimp::pcx
	crimp::sun
	crimp::sgi
    } {
	package require $p
	puts "Using prebuilt $p [package present $p]"
	puts "At [lindex [package ifneeded $p [package present $p]] end]"

    }
} msg]} {
    if {$triedprebuilt} {
	puts "Trying to use prebuilt packages failed ($msg)."
	puts ==\t[join [split $::errorInfo \n] \n==\t]
	puts "Falling back to dynamic compilation via critcl [package require critcl 3]"
    }

    # # ## ### ##### ######## ############# #####################

    ## Override the default of the critcl package for errors and
    ## message. Write them to the terminal (and, for errors, abort the
    ## application instead of throwing them up the stack to an
    ## uncertain catch).

    proc ::critcl::error {msg} {
	global argv0
	puts stderr "$argv0 error: $msg"
	flush stderr
	exit 1
    }

    proc ::critcl::msg {args} {
	switch -exact -- [llength $args] {
	    1 {
		puts stdout [lindex $args 0]
		flush stdout
	    }
	    2 {
		lassign $args o m
		if {$o ne "-nonewline"} {
		    return -code error "wrong\#args, expected: ?-nonewline? msg"
		}
		puts -nonewline stdout $m
		flush stdout
	    }
	    default {
		return -code error "wrong\#args, expected: ?-nonewline? msg"
	    }
	}
	return
    }

    foreach {f p l} {
	crimp_core.tcl crimp::core  {System foundation}
	crimp.tcl      crimp        {Main set of image processing algorithms}
	crimp_tk.tcl   crimp::tk    {Conversion to Tk photo and back}
	crimp_ppm.tcl  crimp::ppm   {Read/write portable pix maps}
	crimp_pgm.tcl  crimp::pgm   {Read/write portable grey maps}
	crimp_pfm.tcl  crimp::pfm   {Read/write portable float maps}
	crimp_bmp.tcl  crimp::bmp   {Read/write Windows bitmaps}
	crimp_pcx.tcl  crimp::pcx   {Read/write zSoft PCX}
	crimp_sun.tcl  crimp::sun   {Read/write Sun Raster}
	crimp_sgi.tcl  crimp::sgi   {Read/write SGI Raster}
    } {
	puts "Trying dynamically compiled package \"$p\""
	# Directly access the package
	source [file join $selfdir $f]
	puts "Using dynamically compiled package \"$p\""
    }
}

wm protocol . WM_DELETE_WINDOW ::exit

puts "Starting up ..."

#puts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n[join [info loaded] \n]
#puts %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# # ## ### ##### ######## #############

proc images_init {} {
    global selfdir images
    set images [lsort -dict [glob -tails -directory $selfdir/images *.png]]
    return
}

proc images_get {index} {
    global images
    return [image_load [lindex $images $index]]
}

proc image_load {name} {
    global selfdir

    set photo [image create photo -file [file join $selfdir images $name]]
    set image [crimp read tk $photo]
    image delete $photo

    return $image
}

# # ## ### ##### ######## #############

proc demo_init {} {
    global selfdir demo demo_index dcurrent demo_map
    set dcurrent {}

    array unset demo     *
    array unset demo_map *

    array set demo {
	aaaaa {
	    label       A:Unmodified
	    cmd         demo_close
	    active      {expr {[bases] == 1}}
	    setup       {}
	    setup_image {}
	    shutdown    {}
	}
    }
    set demo_index(A:Unmodified) [list aaaaa N/A]

    foreach f [glob -directory [demodir] *.tcl] {
	set thedemo {}
	source $f
	set name [dict get $thedemo name]
	set demo_label [dict get $thedemo label]
	set demo_index(${demo_label}) [list ${name} [file tail ${f}]]
	#puts <$thedemo>
	set demo($name) $thedemo
	lappend demo($name) cmd [list demo_use $name]
    }

    foreach l [lsort -dict [array names demo_index]] {
        lappend demo_index(_NAMES_) [lindex $demo_index(${l}) 0]
    }

    foreach name [demo_list] {
	set label [demo_label $name]
	set cmd   [demo_cmd   $name]
	set demo_map($label) $cmd
    }
    return
}

proc demo_list {} {
    global demo_index
    return $demo_index(_NAMES_)
}

proc demo_cmd {name} {
    global demo
    return [dict get $demo($name) cmd]
}

proc demo_label {name} {
    global demo
    return [dict get $demo($name) label]
}

proc demo_use {name} {
    demo_setup $name
    demo_setup_image
    return
}

proc demo_use_image {} {
    demo_setup_image
    return
}

proc demo_setup {name} {
    global demo dcurrent
    demo_close
    set dcurrent $name
    demo_run_hook "\nsetup $name" [dict get $demo($name) setup]
    return
}

proc demo_setup_image {} {
    global dcurrent demo
    catch { spause }
    demo_run_hook image [dict get $demo($dcurrent) setup_image]
    return
}

proc demo_run_hook {label script} {
    if {[catch {
	namespace eval ::DEMO [list demo_time_hook $label $script]
    }]} {
	set prefix "HOOK ERROR "
	log $prefix[join [split $::errorInfo \n] \n$prefix] error
    }
    return
}

proc demo_time_hook {label script} {
    set x [lindex [uplevel 1 [list time $script 1]] 0]

    log "$label = [expr {double($x)/1E6}] seconds"
    if {![bases]} return
    set n [expr {[crimp width [base]]*[crimp height [base]]}]
    log "\t$n pixels"
    log "\t[expr {double($x)/$n}] uSeconds/pixel"
    return
}

proc demo_isactive {} {
    global dcurrent activedemos
    if {$dcurrent eq {}} {return 0}
    return [expr {[demo_label $dcurrent] in $activedemos}]
}

proc demo_close {} {
    global demo dcurrent

    if {![bases]} {

	if {$dcurrent eq {}} return
	namespace eval   ::DEMO [dict get $demo($dcurrent) shutdown]
	namespace delete ::DEMO
	reframe
	set dcurrent {}

	return
    }

    show_image [base]

    if {$dcurrent eq {}} return
    slide_stop
    reframe

    namespace eval   ::DEMO [dict get $demo($dcurrent) shutdown]
    namespace delete ::DEMO
    set dcurrent {}
    return
}

proc demo_usable {} {
    global demo activedemos
    set activedemos {}
    foreach n [demo_list] {
	set active [namespace eval ::DEMO [dict get $demo($n) active]]
	if {!$active} continue
	lappend activedemos [demo_label $n]
    }
    return
}

proc def {name dict} {
    upvar 1 thedemo thedemo
    lappend thedemo \
	setup       {} \
	setup_image {} \
	shutdown    {} \
	active      {
	    expr {[bases] == 1}
	} \
	{*}$dict name $name
    return
}

# # ## ### ##### ######## #############

proc clear {} {
    .log configure -state normal
    .log delete 1.0 end
    .log configure -state disabled
    return
}

proc log {msg {tags {}}} {
    log* $msg\n $tags
    return
}

proc log* {msg {tags {}}} {
    .log configure -state normal
    .log insert end $msg $tags
    .log see end
    .log configure -state disabled
    #update
    return
}

# # ## ### ##### ######## #############

proc reframe {} {
    destroy .left .right .top .bottom .slide

    ttk::frame .slide
    ttk::frame .left
    ttk::frame .top
    ttk::frame .right
    ttk::frame .bottom

    # The slide control is above the paneling
    grid .slide -row 0 -column 1 -sticky swen

    # And this is around the image display in the paneling
    grid .top    -row 0 -column 0 -sticky swen -in .r -columnspan 3
    grid .left   -row 1 -column 0 -sticky swen -in .r
    grid .right  -row 1 -column 2 -sticky swen -in .r
    grid .bottom -row 2 -column 0 -sticky swen -in .r -columnspan 3
    return
}

proc reframe_slide {} {
    destroy    .slide
    ttk::frame .slide

    grid .slide -row 0 -column 1 -sticky swen
    return
}

proc tags {tw} {
    $tw tag configure error   -background #EE5555
    $tw tag configure warning -background yellow
    $tw tag configure note \
	-background lightyellow  \
	-borderwidth 1 -relief sunken
    $tw tag configure separator \
	-background lightblue  \
	-borderwidth 1 -relief sunken
    return
}

proc mag_init {} {
    # Magnifier and tracking locations. Identical when the magnifier
    # is active, otherweise can be different.
    global mx my tx ty magik zsettings zcurrent mag_base mag_bdef

    set mag_base {}
    set mag_bdef 0

    set mx 0 ; set tx 0
    set my 0 ; set ty 0

    # mag'nifier i'nterpolation k'ernel
    set magik [crimp kernel make {{0 1 1}} 1]

    # zoom information. The zcurrent data is always at the end of the
    # zsettings list. Switching between magnifications pulls the
    # chosen setting from the list, and puts the current one into the
    # proper place per the direction of zoom change.

    set zsettings {
	{1 64}
	{2 32}
	{3 16}
	{4  8}
	{5  4}
	{6  2}
	{0  0}
    }

    # magnification is off initially
    set zcurrent {0 0}
    return
}

proc mag_next {} {
    global zcurrent zsettings
    set zcurrent  [lindex $zsettings 0]
    set zsettings [linsert [lrange $zsettings 1 end] end $zcurrent]
    mag_refresh
    return
}

proc mag_previous {} {
    global zcurrent zsettings
    set old $zcurrent
    set zcurrent  [lindex $zsettings end-1]
    set zsettings [linsert [lrange $zsettings 0 end-1] 0 $old]
    mag_refresh
    return
}

proc mag_refresh {} {
    global tx ty
    mag_track _ $tx $ty _ _ _ _
    return
}

proc mag_track {_ x y _ _ _ _} {
    global zcurrent mx my tx ty mag_base mag_bdef

    set x [expr {int($x)}]
    set y [expr {int($y)}]

    lassign $zcurrent scale radius

    .c lower magnifier

    # Remember the last track position, for refresh. Having this
    # separate from the magnifier location ensures that it gets
    # properly moved on refresh, should it be necessary.

    set tx $x
    set ty $y

    # Do nothing without image or magnification disabled.
    if {!$mag_bdef ||
	($scale  == 0) ||
	($radius == 0)} {
	return
    }

    # Move the magnifier on top of the crosshair.
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
	[magnify $scale [mag_pull $mag_base $x $y $radius]]

    .c raise magnifier
    return
}

proc magnify {z i} {
    global magik
    while {$z > 0} {
	set i [crimp interpolate xy $i 2 $magik]
	incr z -1
    }
    return $i
}

proc mag_pull {i x y r} {
    # At x,y, block of radius r.

    set w $r ; incr w $r
    set h $r ; incr h $r

    incr x -$r
    incr y -$r

    # Now the block is explicity specified as rectangle with top-left
    # corner at x,y and width,height; and x,y is relative to the
    # top-left corner of the input image. We can call cut directly,
    # without thinking about image borders. This is all handled inside
    # of the operation, filling BLACK into the parts which lay outside
    # of the input image.

    return [crimp cut $i $x $y $w $h]
}

proc gui {} {
    mag_init
    widgets
    layout
    bindings
    reframe
    wm deiconify .
    return
}

proc widgets {} {
    widget::toolbar .t

    .t add button exit -text Exit   -command ::exit -separator 1
    .t add button relo -text Reload -command reload -separator 1

    ttk::panedwindow .h -orient horizontal
    ttk::panedwindow .v -orient vertical

    ttk::frame .r
    ttk::frame .l

    widget::scrolledwindow .sl -borderwidth 1 -relief sunken ; # log
    widget::scrolledwindow .sc -borderwidth 1 -relief sunken ; # image canvas
    widget::scrolledwindow .si -borderwidth 1 -relief sunken ; # list (image)
    widget::scrolledwindow .sd -borderwidth 1 -relief sunken ; # list (demo)

    text .log -height 5 -width 10 ;#-font {Helvetica -18}
    tags .log

    canvas   .c -scrollregion {-4000 -4000 4000 4000} -cursor dotbox
    listbox  .li -width 15 -selectmode extended -listvariable images
    listbox  .ld -width 30 -selectmode single   -listvariable activedemos

    .c create image {0 0} -anchor nw -tags photo
    .c itemconfigure photo -image [image create photo]

    # Overlay for magnifier.
    .c create image {0 0} -anchor center -tags magnifier
    .c itemconfigure magnifier -image [image create photo]
    return
}

proc layout {} {
    # Place scrollable parts into their managers.

    .sl setwidget .log
    .si setwidget .li
    .sd setwidget .ld
    .sc setwidget .c

    .h add .v
    .h add .r

    .v add .sl
    .v add .l

    # Toolbar/pseudo-menu @ top, with the paneling below.
    grid .t -row 0 -column 0 -sticky swen
    grid .h -row 1 -column 0 -sticky swen -columnspan 2

    grid rowconfigure    . 0 -weight 0
    grid rowconfigure    . 1 -weight 1
    grid columnconfigure . 0 -weight 1

    # Place the image and demo lists side by side.
    grid .si -row 0 -column 0 -rowspan 3 -sticky swen -in .l
    grid .sd -row 0 -column 1 -rowspan 3 -sticky swen -in .l

    grid rowconfigure    .l 0 -weight 1
    grid columnconfigure .l 0 -weight 0
    grid columnconfigure .l 1 -weight 1

    # Image display in the center of the right panel
    grid .sc -row 1 -column 1 -sticky swen -in .r

    grid rowconfigure    .r 0 -weight 0
    grid rowconfigure    .r 1 -weight 1
    grid rowconfigure    .r 2 -weight 0
    grid columnconfigure .r 0 -weight 0
    grid columnconfigure .r 1 -weight 1
    grid columnconfigure .r 2 -weight 0

    return
}

proc bindings {} {
    bind .li <<ListboxSelect>> show_selection
    bind .ld <<ListboxSelect>> show_demo

    # Panning via mouse
    bind .c <ButtonPress-2> {%W scan mark   %x %y}
    bind .c <B2-Motion>     {%W scan dragto %x %y}

    # Cross hairs ...
    #.c configure -cursor tcross
    crosshair::crosshair .c -width 0 -fill \#999999 -dash {.}
    crosshair::track on  .c mag_track

    # Switching magnifications (zoom levels)
    bind .c <3> mag_next
    bind .c <1> mag_previous
    return
}

# # ## ### ##### ######## #############

proc show_selection {} {
    set selection [.li curselection]
    #if {![llength $selection]} return
    show $selection
    demo_usable
    if {[demo_isactive]} {
	demo_use_image
    } else {
	demo_close
    }
    return
}

proc show {indices} {
    global base
    set base {}
    foreach index $indices {
	lappend base [images_get $index]
    }
    return
}

proc show_demo {} {
    global demo_index demo_map activedemos
    set selection [.ld curselection]
    if {![llength $selection]} return
    set index [lindex $selection 0]

    set label [lindex $activedemos $index]
    set command $demo_map($label)
    log "-- ${label} ([lindex $demo_index(${label}) 1]) --" separator

    uplevel #0 $command
    return
}

# # ## ### ##### ######## #############
## Slide show display and control

proc slide_gui {} {
    if {[winfo exists .slide.pc]} return

    ttk::spinbox        .slide.delay -textvariable ::delay -increment 1 -from 10 -to 5000

    widget::arrowbutton .slide.forw  -orientation right   -command slide_forw
    widget::arrowbutton .slide.backw -orientation left    -command slide_backw

    ttk::button         .slide.pc    -image ::play::pause -command slide_pc
    ttk::button         .slide.prev  -image ::play::prev  -command slide_step_prev
    ttk::button         .slide.next  -image ::play::next  -command slide_step_next

    grid .slide.backw -row 0 -column 0 -sticky swen
    grid .slide.forw  -row 0 -column 1 -sticky swen

    grid .slide.prev  -row 0 -column 2 -sticky swen
    grid .slide.pc    -row 0 -column 3 -sticky swen
    grid .slide.next  -row 0 -column 4 -sticky swen
    grid .slide.delay -row 0 -column 5 -sticky swen
    return
}

proc slide_forw {} {
    global direction slides
    if {$direction > 0} return
    set direction 1
    set slides [lreverse $slides]
    return
}

proc slide_backw {} {
    global direction slides
    if {$direction < 0} return
    set direction -1
    set slides [lreverse $slides]
    return
}

proc slide_pc {} {
    global running
    if {$running} {
	spause
    } else {
	scontinue
    }
    return
}

proc slide_step_next {} {
    global direction
    spause
    if {$direction < 0 } { slide_forw ; snext }
    snext
    return
}

proc slide_step_prev {} {
    global direction
    spause
    if {$direction > 0 } { slide_backw ; snext }
    snext
    return
}

proc spause {} {
    .slide.pc configure -image ::play::continue
    update idletasks
    slide_cycle_off
    return
}

proc scontinue {} {
    .slide.pc configure -image ::play::pause
    update idletasks
    slide_cycle
    return
}

proc snext {} {
    global slides 
    if {![info exists slides] || ![llength $slides]} return
    display [cycle slides]
    return
}

namespace eval ::play {}
image create bitmap ::play::continue -data {
    #define continue_width 11
    #define continue_height 11
    static char continue_bits = {
	0x00, 0x00, 0x00, 0x00, 0x0c, 0x00, 0x3c, 0x00, 0xfc, 0x00, 0xfc,
	0x03, 0xfc, 0x00, 0x3c, 0x00, 0x0c, 0x00, 0x00, 0x00, 0x00, 0x00
    }
}

image create bitmap ::play::pause -data {
    #define pause_width 11
    #define pause_height 11
    static char pause_bits = {
	0x00, 0x00, 0x00, 0x00, 0x9c, 0x03, 0x9c, 0x03, 0x9c, 0x03, 0x9c,
	0x03, 0x9c, 0x03, 0x9c, 0x03, 0x9c, 0x03, 0x00, 0x00, 0x00, 0x00
    }
}

image create bitmap ::play::prev -data {
    #define prev_width 11
    #define prev_height 11
    static char prev_bits = {
	0x00, 0x00, 0x00, 0x00, 0x10, 0x01, 0x98, 0x01, 0xcc, 0x00, 0x66,
	0x00, 0xcc, 0x00, 0x98, 0x01, 0x10, 0x01, 0x00, 0x00, 0x00, 0x00
}
}

image create bitmap ::play::next -data {
    #define next_width 11
    #define next_height 11
    static char next_bits = {
	0x00, 0x00, 0x00, 0x00, 0x44, 0x00, 0xcc, 0x00, 0x98, 0x01, 0x30,
	0x03, 0x98, 0x01, 0xcc, 0x00, 0x44, 0x00, 0x00, 0x00, 0x00, 0x00
    }
}

proc slide_stop {} {
    slide_cycle_off
    reframe_slide
    return
}

global delay direction running
set    delay 1000
set    direction 1
set    running 0

proc slide_cycle {} {
    global token delay running
    set running 1

    if {![string is integer $delay]|| ($delay < 1)} {
	set delay 100
    }

    set token [after $delay ::slide_cycle]

    snext
    return
}

proc slide_cycle_off {} {
    global token running
    set running 0
    catch { after cancel $token }
    return
}

proc cycle {lv} {
    upvar 1 $lv list
    set tail [lassign $list head]
    set list [list {*}$tail $head]
    return $head
}

# # ## ### ##### ######## #############
## DEMO API
##
## base       = Returns the currently selected and loaded input image.
## show_image = Display the image argument
## extendgui  = Extend the GUI with a single widget to the left of the
##              image display.  Multiple widgets can be had via a
##              frame.

proc show_slides {images {run 1}} {
    global slides direction
    if {$direction < 0} {
	set slides [lreverse $images]
    } else {
	set slides $images
    }

    slide_gui
    if {$run} {
	scontinue
    } else {
	spause
    }
    return
}

proc show_image {image} {
    slide_stop
    #display [crimp gamma $image 2.2]
    #display [crimp degamma $image 2.2]
    display $image
    log TYPE=[crimp type       $image]
    #log "DIM_=[crimp dimensions $image] @ [crimp at $image]"
    log "DIM_=[crimp dimensions $image]"
    log META=[crimp::meta_get  $image]
    return
}

proc display {image} {
    global mag_base mag_bdef
    .c configure -scrollregion [list 0 0 {*}[crimp dimensions $image]]
    crimp write 2tk [.c itemcget photo -image] $image
    set mag_base $image
    set mag_bdef 1
    mag_refresh
    return
}

proc base {{i 0}} {
    global base
    return [lindex $base $i]
    #return [crimp degamma [lindex $base $i] 2.2]
    #return [crimp gamma [lindex $base $i] 2.2]
}

proc appdir {} {
    global selfdir
    return $selfdir
}

proc demodir {} {
    global selfdir
    return $selfdir/demos
}

proc bases {} {
    global base
    return [llength $base]
}

proc thebases {} {
    global base
    return $base
}

proc reload {} {
    catch { demo_close }
    images_init
    demo_init
    after 100 {
	clear
	log [join [info loaded] \n]
	event generate .li <<ListboxSelect>>
    }
    return
}

# # ## ### ##### ######## #############

proc main {} {
    reload
    gui
    return
    after 100 {
	.li selection set 0
	event generate .li <<ListboxSelect>>
	after 100 {
	    .ld selection set 0
	    event generate .ld <<ListboxSelect>>
	}
    }
    return
}

main
vwait forever
# vim: set sts=4 sw=4 tw=80 et ft=tcl:
