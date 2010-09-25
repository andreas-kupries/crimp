def effect_psychedelia {
    label Psychedelia
    active {
	expr {[bases] == 0}
    }
    setup {
	variable token

	proc next {} {
	    variable token
	    #show_image [crimp psychedelia 320 240 100]
	    show_image [crimp psychedelia 800 600 100]
	    set token [after 100 DEMO::next]
	    return
	}

	next
    }
    shutdown {
	catch {after cancel $token}
    }
}
