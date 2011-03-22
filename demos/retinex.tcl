def effect_retinex {
    label {Retinex}
    setup_image {
	RETINEX [crimp convert 2grey8 [base]]
    }
    setup {
	proc RETINEX {image} {
	    log near/5...    ; set retinexN [SSR $image  5 smoothN]
	    log medium/27... ; set retinexM [SSR $image 27 smoothM]
	    log wide/84...   ; set retinexW [SSR $image 84 smoothW]

	    log multi-scale...
	    # multi-scale from the single scales. nearly an arithmetic mean.
	    set retinex                                  [crimp::scale_float $retinexN 0.3]
	    set retinex [crimp::add_float_float $retinex [crimp::scale_float $retinexM 0.4] 1 0]
	    set retinex [crimp::add_float_float $retinex [crimp::scale_float $retinexW 0.3] 1 0]

	    # Compress the results for display. We use two different
	    # methods to determine the visible range. One is to show
	    # everything from actual minimum to maximum (B), the other
	    # shows a range around the mean, a multiple of the
	    # standard deviation (A).

	    set retinexNa [crimp::FITFLOATB $retinexN]
	    set retinexMa [crimp::FITFLOATB $retinexM]
	    set retinexWa [crimp::FITFLOATB $retinexW]
	    set retinexA  [crimp::FITFLOATB $retinex]

	    set retinexNb [crimp::FITFLOAT $retinexN]
	    set retinexMb [crimp::FITFLOAT $retinexM]
	    set retinexWb [crimp::FITFLOAT $retinexW]
	    set retinexB  [crimp::FITFLOAT $retinex]

	    log montage...
	    #set retinex [crimp alpha set $retinex [lindex [crimp::split $retinex] end]]
	    show_image [crimp montage vertical \
			    [crimp montage horizontal \
				 [border $image] \
				 [border [crimp::FITFLOAT $smoothN]] \
				 [border $retinexNa] \
				 [border $retinexNb] \
				] \
			    [crimp montage horizontal \
				 [border $image] \
				 [border [crimp::FITFLOAT $smoothM]] \
				 [border $retinexMa] \
				 [border $retinexMb] \
				] \
			    [crimp montage horizontal \
				 [border $image] \
				 [border [crimp::FITFLOAT $smoothW]] \
				 [border $retinexWa] \
				 [border $retinexWb] \
				] \
			    [crimp montage horizontal \
				 [border $image] \
				 [border $image] \
				 [border $retinexA] \
				 [border $retinexB] \
				] \
			    ]
	    return
	}

	proc border {i} {
	    crimp expand const $i \
		5 5 5 5 \
		0 0 255
	}

	proc SSR {image sigma vs} {
	    upvar 1 $vs smooth
	    # SSR = Single Scale Retinex.
	    # This implementation is limited to grey8 images. I.e. no color.

	    # R = log ((1+I)/(1+I*G))
	    #   = log (1+I) - log (1+I*G)
	    # * = convolution, and G a gaussian.
	    # We are using 1+ to avoid log()'s singularity at 0 (i.e. black).

	    set image     [::crimp::convert_2float_grey8           $image]
	    set smooth    [::crimp::filter::gauss::sampled         $image $sigma]
	    set logimage  [::crimp::log_float [crimp::offset_float $image 1]]
	    set logsmooth [::crimp::log_float [crimp::offset_float $smooth 1]]
	    set ssr       [::crimp::subtract_float_float $logimage $logsmooth 1 0]

	    return $ssr
	}
    }
}
