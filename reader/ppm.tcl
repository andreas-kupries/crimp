# -*- tcl -*-
# # ## ### ##### ######## #############
# Reader for images in PPM format (Portable Grey Map).
# See http://en.wikipedia.org/wiki/Netpbm_format
# Code derived from http://wiki.tcl.tk/4530
# Handles both raw and plain formats.

namespace eval ::crimp::read {}
proc ::crimp::read::ppm {ppmdata} {
    # Strip out comments
   regsub -all {\#[^\n]*\n} $ppmdata " " ppmdata

   # Determine format, dimensions, and ancillary data.

   if {[regexp {^P6\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)$} \
	    $ppmdata -> w h max raster]} {

       # Raw PPM. The raster is a bytestring. Convert to list of
       # numbers.  We restrict us to the number of pixels to eliminate
       # any junk coming after the raster, which may another PPM
       # image.

       set n [expr {$w*$h}]

       if {$max > 65536} {
	   return -code error "Bad PPM image, max out of bounds."
       } elseif {$max > 256} {
	   # Pixels are 3 * 2 byte bigendian.
	   set raster [string range $raster 0 [expr {6*$n}]]
	   set tmp {}
	   foreach {h l} [split $raster {}] {
	       binary scan $h$l Su1 x
	       lappend tmp $x
	   }
	   set raster $tmp
       } else {
	   # Pixels are 3 * 1 byte.
	   set raster [string range $raster 0 [expr {3*$n}]]
	   set tmp {}
	   foreach b [split $raster {}] {
	       binary scan $b cu1 x
	       lappend tmp $x
	   }
	   set raster $tmp
       }
   } elseif {[regexp {^P3\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)$} \
		  $ppmdata -> w h max raster]} {

       # Plain PPM. Raster is a list of numbers. We restrict us to the
       # number of pixels to eliminate any junk coming after the
       # raster, which may another PPM image.

       set n      [expr {$w*$h}]
       set raster [lrange $raster 0 [expr {3*$n}]]
   } else {
       return -code error "Not a PPM image"
   }

   # Re-scale and -layout the pixels for use by 'read tcl' / XXX NYI.
   set img {}
   set row {}
   foreach {r g b} $raster {
       set r [expr {(255*$r)/$max}]
       set g [expr {(255*$g)/$max}]
       set b [expr {(255*$b)/$max}]
       lappend row [list $r $g $b]
       if {[llength $row] == $w} {
	   lappend img $row
	   set row {}
       }
   }

   # At last construct and return the crimp value.
   return [tcl///NYI $img]
}

# # ## ### ##### ######## #############
return
