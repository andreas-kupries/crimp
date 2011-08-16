## -*- tcl -*-
# # ## ### ##### ######## #############
## This file defines a number of commands on top of the C primitives
## which are easier to use than directly calling on the latter.

package require Tcl 8.5
package require Tk  8.5
package require crimp::core

# # ## ### ##### ######## #############
## Map the new reader primitive into the existing ensemble.

proc ::crimp::read::bmp {bmpdata} {
    ::crimp::read_bmp $bmpdata
}

# # ## ### ##### ######## #############
return
