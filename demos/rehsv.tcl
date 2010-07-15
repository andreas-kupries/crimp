def effect_rehsv {
    label {Change HSV}
    setup {
	set ::HSVBASE [crimp convert 2hsv [base]]

	set ::GHG 1
	set ::GHB 0
	set ::TH [crimp table gainw $::GHG $::GHB]
	set ::MH [crimp map   gainw $::GHG $::GHB]

	set ::GS 1 ; set ::TS [crimp table gain $::GS] ; set ::MS [crimp map gain $::GS]
	set ::GV 1 ; set ::TV [crimp table gain $::GV] ; set ::MV [crimp map gain $::GV]

	proc ::HG {gain} {
	    set ::TH [crimp table gainw $gain $::GHB]
	    set ::MH [crimp map   gainw $gain $::GHB]
	    UPDATE
	}
	proc ::HB {bias} {
	    set ::TH [crimp table gainw $::GHG $bias]
	    set ::MH [crimp map   gainw $::GHG $bias]
	    UPDATE
	}
	proc ::S {gain} {
	    set ::TS [crimp table gain $gain]
	    set ::MS [crimp map   gain $gain]
	    UPDATE
	}
	proc ::V {gain} {
	    set ::TV [crimp table gain $gain]
	    set ::MV [crimp map   gain $gain]
	    UPDATE
	}

	proc ::UPDATE {} {
	    global MH MS MV HSVBASE
	    show_image [crimp convert 2rgb [crimp remap $HSVBASE $MH $MS $MV]]
	    return
	}

	scale .left.hg -variable ::GHG -from 0 -to 20  -resolution 0.01 -orient vertical -command ::HG
	scale .left.hb -variable ::GHB -from 0 -to 255 -resolution 1    -orient vertical -command ::HB
	scale .left.s  -variable ::GS  -from 0 -to 20  -resolution 0.01 -orient vertical -command ::S
	scale .left.v  -variable ::GV  -from 0 -to 20  -resolution 0.01 -orient vertical -command ::V

	plot  .left.ph -variable ::TH
	plot  .left.ps -variable ::TS
	plot  .left.pv -variable ::TV

	grid .left.hg -row 0 -column 0 -sticky sen
	grid .left.ph -row 0 -column 1 -sticky swen
	grid .left.hb -row 0 -column 2 -sticky sen

	grid .left.pv -row 1 -column 1 -sticky swen
	grid .left.v  -row 1 -column 2 -sticky sen

	grid .left.ps -row 2 -column 1 -sticky swen
	grid .left.s  -row 2 -column 2 -sticky sen
    }
    shutdown {
	rename ::HG {}
	rename ::HB {}
	rename ::S {}
	rename ::V {}
	unset ::GHG ::GHB ::GS ::GV ::TH ::TS ::TV ::MH ::MS ::MV ::HSVBASE
    }
}
