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

   # Re-scale and -layout the pixels for use by 'read tcl'. Note how
   # we are placing the data in three separate planes. These become
   # three separate greyscale images which are then joined into the
   # final RGB.

   set imgr {} ; set rowr {}
   set imgg {} ; set rowg {}
   set imgb {} ; set rowb {}

   foreach {r g b} $raster {
       set r [expr {(255*$r)/$max}] ; lappend rowr $r
       set g [expr {(255*$g)/$max}] ; lappend rowg $g
       set b [expr {(255*$b)/$max}] ; lappend rowb $b

       if {[llength $rowr] == $w} {
	   lappend imgr $rowr ; set rowr {}
	   lappend imgg $rowg ; set rowg {}
	   lappend imgb $rowb ; set rowb {}
       }
   }

   # At last construct and return the crimp value.
   return [crimp join 2rgb \
	       [tcl $imgr] \
	       [tcl $imgg] \
	       [tcl $imgb]]
}

# # ## ### ##### ######## #############
return
