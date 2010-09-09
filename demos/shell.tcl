def effect_a_shell {
    label {Interactive Shell}
    setup {
	# TODO : Command history! Result history ?

	namespace eval ::DEMO::EVAL {
	    namespace import ::crimp::*
	    namespace import ::base
	}

	variable cmd {}

	proc showit {} {
	    variable cmd
	    if {$cmd eq {}} return
	    .top.cmd configure -state disabled ; update ; # coroutine?!
	    show_image [namespace eval ::DEMO::EVAL $cmd]
	    .top.cmd configure -state normal ; update
	}

	ttk::entry .top.cmd
	pack       .top.cmd -side top -expand 1 -fill both

	bind .top.cmd <Return> {::apply {{} {
	    variable cmd [.top.cmd get]
	    showit
	} ::DEMO}}
    }
    setup_image {
	showit
    }
}
