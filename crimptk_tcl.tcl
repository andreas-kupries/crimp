## -*- tcl -*-
# # ## ### ##### ######## #############
## This file defines a number of commands on top of the C primitives
## which are easier to use than directly calling on the latter.

package require Tcl 8.5
package require Tk  8.5
package require crimp

namespace eval ::crimp {}

# # ## ### ##### ######## #############
## Implement the reader directly. The ensemble already exists, and is
## automatically extended.

namespace eval ::crimp::read {}

proc ::crimp::read::2tk {detail} {
    ::crimp::read_2tk $detail
}

# # ## ### ##### ######## #############
## Implement the writer directly. The ensemble already exists, and is
## automatically extended.

namespace eval ::crimp::write {}

proc ::crimp::write::2tk {dst image} {
    set type [::crimp::TypeOf $image]
    set f    write_2tk_${type}
    if {![::crimp::Has $f]} {
	return -code error "Unable to write images of type \"$type\" to \"tk\""
    }
    return [::crimp::$f $dst $image]
}

# # ## ### ##### ######## #############
return
