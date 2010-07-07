def psychedelia {
    label Psychedelia
    setup {
	proc ::P {} {
	    show_image [crimp psychedelia 320 240 100]
	    set ::PX [after 100 ::P]
	}
	::P
    }
    shutdown {
	after cancel $::PX
    }
}
