def effect_retinex {
    label {Retinex}
    setup_image {
	RETINEX [crimp convert 2grey8 [base]]
    }
    setup {
	proc RETINEX {image} {
	    log near/5...    ; set retinexN [SSR $image  5]
	    log medium/27... ; set retinexM [SSR $image 27]
	    log wide/84...   ; set retinexW [SSR $image 84]

	    log multi-scale...
	    # multi-scale from the single scales. nearly an arithmetic mean.
	    set retinex                                  [crimp::scale_float $retinexN 0.3]
	    set retinex [crimp::add_float_float $retinex [crimp::scale_float $retinexM 0.4] 1 0]
	    set retinex [crimp::add_float_float $retinex [crimp::scale_float $retinexW 0.3] 1 0]

	    # Compress the results for display. We use two different
	    # methods to determine the visible range. One is to show
	    # everything from actual minimum to maximum, the other
	    # shows a range around the mean, a multiple of the
	    # standard deviation. See 'coupling' in Mean-Stddev for
	    # the factor.

	    set retinexNa [crimp::FITFLOATRANGE $retinexN {*}[Mean-Stddev $retinexN]]
	    set retinexMa [crimp::FITFLOATRANGE $retinexM {*}[Mean-Stddev $retinexM]]
	    set retinexWa [crimp::FITFLOATRANGE $retinexW {*}[Mean-Stddev $retinexW]]
	    set retinexA  [crimp::FITFLOATRANGE $retinex  {*}[Mean-Stddev $retinex]]

	    set retinexNb [crimp::FITFLOATRANGE $retinexN {*}[Min-Max     $retinexN]]
	    set retinexMb [crimp::FITFLOATRANGE $retinexM {*}[Min-Max     $retinexM]]
	    set retinexWb [crimp::FITFLOATRANGE $retinexW {*}[Min-Max     $retinexW]]
	    set retinexB  [crimp::FITFLOATRANGE $retinex  {*}[Min-Max     $retinex]]

	    log montage...
	    #set retinex [crimp alpha set $retinex [lindex [crimp::split $retinex] end]]
	    show_image [crimp montage vertical \
			    [crimp montage horizontal \
				 [border $image] \
				 [border $retinexNa] \
				 [border $retinexNb] \
				] \
			    [crimp montage horizontal \
				 [border $image] \
				 [border $retinexMa] \
				 [border $retinexMb] \
				] \
			    [crimp montage horizontal \
				 [border $image] \
				 [border $retinexWa] \
				 [border $retinexWb] \
				] \
			    [crimp montage horizontal \
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

	proc SSR {image sigma} {
	    # SSR = Single Scale Retinex.
	    # This implementation is limited to grey8 images. I.e. no color.

	    # R = a*(log (I+1) - log (I#G+1))+b
	    # where a, b are parameters to convert the result back into the 0..255 range
	    # * = multip,, # = convolution, and G a gaussian.
	    # We are using +1 to avoid log() singularity at 0.

	    set image     [::crimp::convert_2float_grey8           $image]
	    set smooth    [::crimp::filter::gauss::sampled         $image $sigma]
	    set logimage  [::crimp::log_float [crimp::offset_float $image 1]]
	    set logsmooth [::crimp::log_float [crimp::offset_float $smooth 1]]
	    set ssr       [::crimp::subtract_float_float $logimage $logsmooth 1 0]

	    return $ssr
	}

	proc Mean-Stddev {image} {
	    set coupling 1.2

	    set statistics [crimp::stats_float $image]
	    log Fms=$statistics

	    # This command uses mean and standard deviation to select
	    # the visible range.

	    set mean [dict get $statistics value mean]
	    set var  [dict get $statistics value stddev]

	    set min [expr {$mean - $var * $coupling}]
	    set max [expr {$mean + $var * $coupling}]

	    return [list $min $max]
	}

	proc Min-Max {image} {
	    set statistics [crimp::stats_float $image]
	    log Fmm=$statistics

	    # This command uses min and max to select
	    # the visible range.

	    set min [dict get $statistics value min]
	    set max [dict get $statistics value max]

	    return [list $min $max]
	}
    }
}
