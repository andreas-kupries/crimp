# # ## ### ##### ######## ############# #####################
## -*- tcl *-

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require Tk
package require snit          ; # Tcllib
package require Plotchart 1.9 ; # Tklib

# # ## ### ##### ######## ############# #####################
## Implementation

snit::widget plot {
    # # ## ### ##### ######## ############# #####################
    constructor {args} {
	canvas $win.c -bg white
	pack   $win.c -side top -expand 1 -fill both
        $self configurelist $args
	return
    }


    # # ## ### ##### ######## ############# #####################
    option  -variable -configuremethod C-variable
    method C-variable {o value} {
	if {$options($o) ne {}} {
	    trace remove variable $options($o) write [mymethod UpdateData]
	}
	set options($o) $value
	if {$options($o) ne {}} {
	    trace add variable $options($o) write [mymethod Refresh]

	    # Force update now, to handle pre-existing data in the
	    # variable, if any, as such does not invoke the trace.
	    $self Refresh
	}
	return
    }
    # # ## ### ##### ######## ############# #####################
    # # ## ### ##### ######## ############# #####################

    method Refresh {args} {
	catch { after cancel $myupdate }
	set myupdate [after idle [mymethod UpdateData]]
	return
    }

    method UpdateData {} {
	upvar #0 $options(-variable) series
	if {![info exists series]} return

	if {!$options(-locked)} {
	    set  yscale [::Plotchart::determineScaleFromList $series]
	    lset yscale 0 0
	} else {
	    set yscale {0 255 64}
	}

	if {!$options(-xlocked)} {
	    set  xscale [::Plotchart::determineScaleFromList [list 0 [llength $series]]]
	    lset xscale 0 0
	} else {
	    set xscale {0 255 64}
	}

	$win.c delete all

	set myplot [Plotchart::createXYPlot $win.c $xscale $yscale]
	$myplot title $options(-title)
	$myplot dataconfig series -color $options(-color)
	$myplot xconfig -format %d

	set x 0
	foreach y $series {
	    $myplot plot series $x $y
	    incr x
	}
	return
    }

    # # ## ### ##### ######## ############# #####################

    option  -color -default blue -configuremethod C-color
    method C-color {o value} {
	set options($o) $value
	catch {
	    $myplot dataconfig series -color $value
	}
	return
    }

    option  -title -default {} -configuremethod C-title
    method C-title {o value} {
	set options($o) $value
	catch {
	    $myplot title $value
	}
	return
    }

    # # ## ### ##### ######## ############# #####################

    option -locked -default 1 -configuremethod C-locked
    method C-locked {o value} {
	set options($o) $value
	$self Refresh
	return
    }

    option -xlocked -default 1 -configuremethod C-locked

    # # ## ### ##### ######## ############# #####################

    variable myplot   {} ; # plotchar xyplot for the series
    variable myupdate {} ; # idle token for defered update

    # # ## ### ##### ######## ############# #####################
}

# # ## ### ##### ######## ############# #####################
## ready

package provide plot 1
return
