def effect_contrast {
    label {Contrast}
    setup_image {
	variable base [base]
	variable grey [crimp convert 2grey8 [base]]
	NORM
    }
    setup {
	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}

	proc NORM {} {
	    variable base ; set nb [crimp contrast normalize $base]
	    variable grey ; set ng [crimp contrast normalize $grey]

	    show_image [crimp montage vertical \
			    [crimp montage horizontal \
				 [border $base] \
				 [border $nb]] \
			    [crimp convert 2rgba \
				 [crimp montage horizontal \
				      [border $grey] \
				      [border $ng]]]]
	}

	proc EQG {} {
	    variable base
	    variable grey

	    show_image [crimp montage vertical \
			    [crimp montage horizontal \
				 [border $base] \
				 [border [crimp contrast equalize global $base]]] \
			    [crimp convert 2rgba \
				 [crimp montage horizontal \
				      [border $grey] \
				      [border [crimp contrast equalize global $grey]]]]]
	}

	proc EQL {} {
	    variable base
	    variable grey

	    show_image [crimp montage vertical \
			    [crimp montage horizontal \
				 [border $base] \
				 [border [crimp contrast equalize local $base]]] \
			    [crimp convert 2rgba \
				 [crimp montage horizontal \
				      [border $grey] \
				      [border [crimp contrast equalize local $grey]]]]]
	}

	ttk::button .top.nrm -text Normalized -command ::DEMO::NORM
	ttk::button .top.eqg -text Eq/Global  -command ::DEMO::EQG
	ttk::button .top.eql -text Eq/Local   -command ::DEMO::EQL

	grid .top.nrm -row 0 -column 0 -sticky swen
	grid .top.eqg -row 0 -column 1 -sticky swen
	grid .top.eql -row 0 -column 2 -sticky swen
    }
}
