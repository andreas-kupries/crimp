# -*- tcl -*-
# CRIMP :: Tk == C Runtime Image Manipulation Package :: Tk Photo Conversion.
#
# (c) 2010      Andrew M. Goth  http://wiki.tcl.tk/andy%20goth
# (c) 2010-2011 Andreas Kupries http://wiki.tcl.tk/andreas%20kupries
#

# # ## ### ##### ######## #############
## Requisites

package require critcl       3
package require critcl::util 1

# # ## ### ##### ######## #############

if {![critcl::compiling]} {
    error "Unable to build CRIMP::TK, no proper compiler found."
}

# # ## ### ##### ######## #############
## Get the local support code. We source it directly because this is
## only needed for building the package, in any mode, and not during
## the runtime. Thus not added to the 'tsources'.

::apply {{here} {
    source $here/support.tcl
}} [file dirname [file normalize [info script]]]

# # ## ### ##### ######## #############
## Administrivia

critcl::license \
    {Andreas Kupries} \
    {Under a BSD license.}

critcl::summary \
    {Extension of the CRIMP core to handle import and export of Tk photos}

critcl::description {
    This package provides the CRIMP eco-system with the functionality to handle
    images stored in Tk photo images. This means that this package is dependent
    on Tk, and thus the presence of a windowing system, like X11, or Aqua.
}

critcl::subject image {Tk photo image} {Tk photo} {Tk photo import} {Tk photo export}
critcl::subject image {image import} {image export}
critcl::subject photo {photo import} {photo export}

# # ## ### ##### ######## #############
## Implementation.

critcl::tcl 8.5
critcl::tk

# # ## ### ##### ######## #############
## Declare the Tcl layer aggregating the C primitives into useful
## commands. After the Tcl-based readers and writers to properly pick
## them up too in the ensembles.

critcl::tsources policy_tk.tcl

# # ## ### ##### ######## #############
## Chart helpers.

critcl::tsources plot.tcl

# # ## ### ##### ######## #############
## C-level API (i.e. stubs and types)

critcl::api import crimp::core 0.1

# # ## ### ##### ######## #############
## Main C section.

critcl::ccode {
    #include <math.h>
    #include <stdlib.h>
    #include <string.h>
}

# # ## ### ##### ######## #############
## Pull in the Tk-specific pieces. These are fit under the read/write namespaces.

critcl::owns        format/*tk*.crimp
crimp_source_cproc {format/*tk*.crimp}

# # ## ### ##### ######## #############
## Make the C pieces ready. Immediate build of the binaries, no deferal.

if {![critcl::load]} {
    error "Building and loading CRIMP::TK failed."
}

# # ## ### ##### ######## #############

package provide crimp::tk 0.1
return

# vim: set sts=4 sw=4 tw=80 et ft=tcl:
