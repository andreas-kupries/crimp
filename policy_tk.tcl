## -*- tcl -*-
## Tcl level definitions for crimp::tk.
# # ## ### ##### ######## ############# #####################
## This file defines a number of commands on top of the C primitives
## which are easier to use than directly calling on the latter.

# # ## ### ##### ######## ############# #####################
## Reading Tk photos is handled at the C level, and the command
## is directly fit into the ::crimp::read ensemble.

# # ## ### ##### ######## ############# #####################
## Writing to Tk photos is handled by a custom method in the
## ::crimp::write ensemble, outside of the standard 2xxx methods.
## This auto-dispatches to the actual primitives, also under
## ::crimp::write, using private command names.

proc ::crimp::write::2tk {dst image} {
    set type [::crimp::TypeOf $image]
    set fun  write::Tk_${type}
    if {![::crimp::Has $fun]} {
	return -code error "Unable to write images of type \"$type\" to \"tk\""
    }
    return [::crimp::$fun $dst $image]
}

# # ## ### ##### ######## #############
return
