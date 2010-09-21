# -*- tcl -*- 
# # ## ### ##### ######## #############
# Reader for images in PGM format (Portable Grey Map).
# See http://en.wikipedia.org/wiki/Netpbm_format
# Code derived from http://wiki.tcl.tk/4530
# Handles both raw and plain formats.

namespace eval ::crimp::read {}
proc ::crimp::read::pgm {pgmdata} {
    # Strip out comments
   regsub -all {\#[^\n]*\n} $pgmdata " " pgmdata

   # Determine format, dimensions, and ancillary data.

   if {[regexp {^P5\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)$} \
	    $pgmdata -> w h max raster]} {

       # Raw PGM. The raster is a bytestring. Convert to list of
       # numbers.  We restrict us to the number of pixels to eliminate
       # any junk coming after the raster, which may another PGM
       # image.

       set n [expr {$w*$h}]

       if {$max > 65536} {
	   return -code error "Bad PGM image, max out of bounds."
       } elseif {$max > 256} {
	   # Pixels are 2 byte bigendian.
	   set raster [string range $raster 0 [expr {2*$n}]]
	   set tmp {}
	   foreach {h l} [split $raster {}] {
	       binary scan $h$l Su1 x
	       lappend tmp $x
	   }
	   set raster $tmp
       } else {
	   # Pixels are 1 byte.
	   set raster [string range $raster 0 $n]
	   set tmp {}
	   foreach b [split $raster {}] {
	       binary scan $b cu1 x
	       lappend tmp $x
	   }
	   set raster $tmp
       }
   } elseif {[regexp {^P2\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*)$} \
		  $pgmdata -> w h max raster]} {

       # Plain PGM. Raster is a list of numbers. We restrict us to the
       # number of pixels to eliminate any junk coming after the
       # raster, which may another PGM image.

       set n      [expr {$w*$h}]
       set raster [lrange $raster 0 $n]
   } else {
       return -code error "Not a PGM image"
   }

   # Re-scale and -layout the pixels for use by 'read tcl'.
   set img {}
   set row {}
   foreach p $raster {
       lappend row [expr {(255*$p)/$max}]
       if {[llength $row] == $w} {
	   lappend img $row
	   set row {}
       }
   }

   # At last construct and return the crimp value.
   return [tcl $img]
}

# # ## ### ##### ######## #############
return
