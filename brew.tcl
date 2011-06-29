#!/bin/sh
# -*- tcl -*- \
exec tclsh "$0" ${1+"$@"}
package require Tcl 8.5
set me [file normalize [info script]]
proc main {} {
    global argv tcl_platform tag
    set tag {}
    if {![llength $argv]} {
	if {$tcl_platform(platform) eq "windows"} {
	    set argv gui
	} else {
	    set argv help
	}
    }
    if {[catch {
	eval _$argv
    }]} usage
    exit 0
}
proc usage {{status 1}} {
    global errorInfo
    if {($errorInfo ne {}) &&
	![string match {invalid command name "_*"*} $errorInfo]
    } {
	puts stderr $::errorInfo
	exit
    }

    global argv0
    puts stderr "Usage: $argv0 ?install ?dst?|starkit ?dst? ?interp?|starpack prefix ?dst?|help|recipes? ?gui?"
    exit $status
}
proc tag {t} {
    global tag
    set tag $t
    return
}
proc myexit {} {
    tag ok
    puts DONE
    return
}
proc log {args} {
    global tag
    set newline 1
    if {[lindex $args 0] eq "-nonewline"} {
	set newline 0
	set args [lrange $args 1 end]
    }
    if {[llength $args] == 2} {
	lassign $args chan text
	if {$chan ni {stdout stderr}} {
	    ::_puts {*}[lrange [info level 0] 1 end]
	    return
	}
    } else {
	set text [lindex $args 0]
	set chan stdout
    }
    # chan <=> tag, if not overriden
    if {$tag eq {}} { set tag $chan }
    #::_puts $tag/$text

    .t insert end-1c $text $tag
    set tag {}
    if {$newline} { 
	.t insert end-1c \n
    }

    update
    return
}
proc +x {path} {
    catch { file attributes $path -permissions u+x }
    return
}
proc grep {file pattern} {
    set lines [split [read [set chan [open $file r]]] \n]
    close $chan
    return [lsearch -all -inline -glob $lines $pattern]
}
proc version {file} {
    return [lindex [grep $file {*package provide*}] 0 3]
}
proc _help {} {
    usage 0
    return
}
proc _recipes {} {
    set r {}
    foreach c [info commands _*] {
	lappend r [string range $c 1 end]
    }
    puts [lsort -dict $r]
    return
}
proc _install {{dst {}}} {
    if {[llength [info level 0]] < 2} {
	set dst [info library]
	set idir [file dirname [file dirname $dst]]/include
    } else {
	set idir [file dirname $dst]/include
    }

    package require critcl::app

    # Package: crimp
    # Build binaries
    set src     [file dirname $::me]/crimp.tcl
    set version [version $src]

    file delete -force             [pwd]/BUILD
    critcl::app::main [list -cache [pwd]/BUILD -libdir $dst -includedir $idir -pkg $src]
    file delete -force $dst/crimp$version
    file rename        $dst/crimp $dst/crimp$version

    puts -nonewline "Installed package:     "
    tag ok
    puts $dst/crimp$version


    # Package: crimp::tk
    # Build binaries
    set src     [file dirname $::me]/crimptk.tcl
    set version [version $src]

    file delete -force             [pwd]/BUILDTK
    critcl::app::main [list -cache [pwd]/BUILDTK -libdir $dst -includedir $idir -pkg crimp::tk $src]
    file delete -force $dst/crimptk$version
    file rename        $dst/crimptk $dst/crimptk$version

    puts -nonewline "Installed package:     "
    tag ok
    puts $dst/crimptk$version
    return
}
proc _gui {} {
    global INSTALLPATH
    package require Tk
    package require widget::scrolledwindow

    label  .l -text {Install Path: }
    entry  .e -textvariable ::INSTALLPATH
    button .i -command Install -text Install

    widget::scrolledwindow .st -borderwidth 1 -relief sunken
    text   .t
    .st setwidget .t

    .t tag configure stdout -font {Helvetica 8}
    .t tag configure stderr -background red   -font {Helvetica 12}
    .t tag configure ok     -background green -font {Helvetica 8}

    grid .l  -row 0 -column 0 -sticky new
    grid .e  -row 0 -column 1 -sticky new
    grid .i  -row 0 -column 2 -sticky new
    grid .st -row 1 -column 0 -sticky swen -columnspan 2

    grid rowconfigure . 0 -weight 0
    grid rowconfigure . 1 -weight 1

    grid columnconfigure . 0 -weight 0
    grid columnconfigure . 1 -weight 1
    grid columnconfigure . 2 -weight 0

    set INSTALLPATH [info library]

    # Redirect all output into our log window, and disable uncontrolled exit.
    rename ::puts ::_puts
    rename ::log ::puts
    rename ::exit   ::_exit
    rename ::myexit ::exit

    # And start to interact with the user.
    vwait forever
    return
}
proc Install {} {
    global INSTALLPATH
    .i configure -state disabled

    set fail [catch {
	_install $INSTALLPATH

	puts ""
	tag ok
	puts DONE
    } e o]

    .i configure -state normal
    .i configure -command ::_exit -text Exit -bg green

    if {$fail} {
	# rethrow
	return {*}$o $e
    }
    return
}
proc _wrap4tea {{dst {}}} {
    if {[llength [info level 0]] < 2} {
	set dst [file join [pwd] tea]
    }

    package require critcl::app

    # Package: crimp
    # Generate TEA directory hierarchy
    set src     [file dirname $::me]/crimp.tcl
    set version [version $src]

    file delete -force             [pwd]/BUILD
    critcl::app::main [list -cache [pwd]/BUILD -libdir $dst -tea $src]
    file delete -force $dst/crimp$version
    file rename        $dst/crimp $dst/crimp$version

    puts "Installed package:     $dst/crimp$version"


    # Package: crimp::tk
    # Generate TEA directory hierarchy
    set src     [file dirname $::me]/crimptk.tcl
    set version [version $src]

    file delete -force             [pwd]/BUILDTK
    critcl::app::main [list -cache [pwd]/BUILDTK -libdir $dst -tea crimp::tk $src]
    file delete -force $dst/crimptk$version
    file rename        $dst/crimptk $dst/crimptk$version

    puts "Installed package:     $dst/crimptk$version"
    return
}
main
