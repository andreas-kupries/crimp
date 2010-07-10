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
	set myplot [Plotchart::createXYPlot $win.c {0 255 64} {0 255 64}]
	$myplot dataconfig series -color blue
	$myplot xconfig -format %d
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
	    trace add variable $options($o) write [mymethod UpdateData]
	    #catch { after cancel $myupdate }
	    #set myupdate [after idle [mymethod UpdateData]]
	}
	return
    }
    # # ## ### ##### ######## ############# #####################
    # # ## ### ##### ######## ############# #####################

    method UpdateData {args} {
	upvar #0 $options(-variable) series
	catch {	$win.c delete series }      msg ;# puts a|$msg|
	catch {	$myplot plot series {} {} } msg ;# puts b|$msg|
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
	$myplot dataconfig series -color $value
	return
    }

    # # ## ### ##### ######## ############# #####################

    variable myplot   {} ; # plotchar xyplot for the series
    variable myupdate {} ; # idle token for defered update

    # # ## ### ##### ######## ############# #####################
}

# # ## ### ##### ######## ############# #####################
## ready

package provide plot 1
return
