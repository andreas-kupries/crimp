def effect_retinex_hsv {
    label {Retinex/HSV}
    setup_image {
	RETINEX [base]
    }
    setup {
	proc RETINEX {image} {
	    # color retinex by processing in HSV, working on only the
	    # V (luma) channel.

	    lassign [crimp split [crimp convert 2hsv $image]] h s v

	    log near/5...    ; set retinexN [SSR $v  5 smoothN]
	    log medium/27... ; set retinexM [SSR $v 27 smoothM]
	    log wide/84...   ; set retinexW [SSR $v 84 smoothW]

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

	    set retinexNa [crimp join 2hsv $h $s [crimp::FITFLOATB $retinexN]]
	    set retinexMa [crimp join 2hsv $h $s [crimp::FITFLOATB $retinexM]]
	    set retinexWa [crimp join 2hsv $h $s [crimp::FITFLOATB $retinexW]]
	    set retinexA  [crimp join 2hsv $h $s [crimp::FITFLOATB $retinex]]

	    set retinexNb [crimp join 2hsv $h $s [crimp::FITFLOAT $retinexN]]
	    set retinexMb [crimp join 2hsv $h $s [crimp::FITFLOAT $retinexM]]
	    set retinexWb [crimp join 2hsv $h $s [crimp::FITFLOAT $retinexW]]
	    set retinexB  [crimp join 2hsv $h $s [crimp::FITFLOAT $retinex]]

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
	    crimp expand const [crimp convert 2rgb $i] \
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
