def op_l0smoothing {
    label {L0 Smoothing}
    setup_image {
	showsmooth [base]
    }
    setup {
	proc showsmooth {i} {
	    # Do the smoothing separately on each channel. While this
	    # is not how the original performs the operation it is
	    # easier to implement. I will have to see how much this
	    # affects the result.

	    foreach c [crimp split [crimp convert 2rgb $i]] {
		lappend res [l0smooth $c 0.005]
	    }

	    show_image [crimp join 2rgb {*}$res]
	    return
	}

	proc showsmooth {i} {
	    # Do the smoothing separately on each channel. While this
	    # is not how the original performs the operation it is
	    # easier to implement. I will have to see how much this
	    # affects the result.

	    show_image [l0smooth [crimp convert 2grey8 $i] 0.005]
	    return
	}

	namespace eval l0smooth {
	    variable DX [crimp kernel make {{ 0  1  -1}}]
	    variable DY [crimp kernel transpose $DX]
	    # DX, DY :: sgrey8, convolution kernel, spatial
	}

	proc l0smooth::Setup {} {
	    variable DX
	    variable DY
	    upvar 1 lambda lambda	; # :: scalar float
	    upvar 1 beta0  beta0	; # :: scalar float
	    upvar 1 image  image	; # :: img    grey8 -> float, spatial
	    upvar 1 result result	; # :: img    float, spatial
	    upvar 1 beta   beta		; # :: scalar float
	    upvar 1 count  count	; # :: scalar int
	    upvar 1 f1     f1		; # :: img    complex, frequency
	    upvar 1 fi     fi		; # :: img    complex, frequency
	    upvar 1 cfdx   cfdx		; # :: img    complex, frequency
	    upvar 1 cfdy   cfdy		; # :: img    complex, frequency
	    upvar 1 denom  denom	; # :: img    float, frequency

	    # beta0 default = 2 lambda
	    if {$beta0 eq {}} {
		set beta0 [expr {2* $lambda}]
	    }

	    set image [crimp convert 2float $image]
	    # image :: img float

	    # loop initialization
	    set result $image
	    set beta   $beta0
	    set count  0

	    # Constant parts of the loop moved upfront.
	    # TODO: FFT of the delta function
	    # ????: Delta against what ?

	    #set f1 [crimp convert 2complex [crimp blank float {*}[crimp dimensions $image] 1.0]]
	    # ATTENTION ! NOTE: The above is likely wrong.
	    lassign [crimp dimensions $image] w h ; incr w -1 ; incr h -1
	    set f1 [crimp fft forward \
			[crimp convert 2complex \
			     [crimp expand const \
				  [crimp blank float 1 1 1.0] \
				  0 0 $w $h 0.0]]]
	    # ATTENTION ! NOTE: The above is likely wrong.

	    set fi [crimp fft forward [crimp convert 2complex $image]]
	    # f1 :: img complex, frequency
	    # fi :: img complex, frequency


	    # FFT of the convolution kernels ...
	    # We assume that DX/DY are smaller than image in all respects.
	    # This will fail when the input image gets smaller than 3x3.
	    set dx [lindex [crimp matchsize [crimp kernel image $DX] $image] 0]
	    set dy [lindex [crimp matchsize [crimp kernel image $DY] $image] 0]
	    # dx, dy :: img grey8, spatial

	    set fdx [crimp fft forward [crimp convert 2complex $dx]]
	    set fdy [crimp fft forward [crimp convert 2complex $dy]]
	    # fdx, fdy :: img complex, frequency

	    # Conjugates. See Solve8.
	    set cfdx [crimp complex conjugate $fdx]
	    set cfdy [crimp complex conjugate $fdy]
	    # cfdx, cfdy :: img complex, frequency

	    if 0 {
		# Standard formulation, multiplication of complex conjugates.
		# With a float result embedded in complex. However, in Solve12
		# we have to cast to float and back for some calculations. Using
		# the alternate formula below helps reducing on ops.
		set denom [crimp add \
			       [crimp multiply $cfdx $fdx] \
			       [crimp multiply $cfdy $fdy]]
	    }

	    # Alternate formulation, without using a conjugate, and keeping
	    # the result as float. This avoids unnecessary casts here and in
	    # Solve12.

	    set denom [crimp add \
			   [crimp square [crimp complex real $fdx]] \
			   [crimp square [crimp complex real $fdy]]]

	    # denom :: img float, frequency
	    return
	}

	proc l0smooth::Solve12 {} {
	    variable DX
	    variable DY
	    upvar 1 lambda lambda	; # :: scalar float
	    upvar 1 beta   beta		; # :: scalar float
	    upvar 1 h      h		; # :: img float, spatial
	    upvar 1 v      v		; # :: img float, spatial
	    upvar 1 result result	; # :: img float, spatial

	    log \tEq/12;update

	    # Equation 12: Solve for (new) h, v using the last round
	    # result.

	    # TODO - The paper defines gradient as difference between
	    # adjacent pixels => Convolve [1,-1], and transposed.
	    # Question is, can we do the fast gaussian 01/10 commands
	    # here, with a fixed sigma ?

	    # TODO: Gradient for RGB it seems to be euclidean distance
	    # between pixel values treated as 3-vectors. Investigate
	    # what happens if we solve this either separately in each
	    # channel, or just in luma instead of using this RGB
	    # distance.

	    # result :: img float, spatial

	    set dx [crimp filter convolve $result $DX]
	    set dy [crimp filter convolve $result $DY]
	    # dx, dy :: img float, spatial

	    set threshold [crimp add [crimp square $dx] [crimp square $dy]]
	    # threshold :: img float, spatial

	    # h = << 0, for threshold <= lambda/beta, and dx otherwise >>
	    # v = << 0, for threshold <= lambda/beta, and dy otherwise >>

	    # mult = << 0, for threshold <= lambda/beta, and 1 otherwise >>
	    #      = (T <= t) ? 0 : 1
	    #      = (T >  t) ? 1 : 0
	    #      = above (T, t)
	    set threshold [crimp threshold global above \
			       $threshold \
			       [expr {$lambda / $beta}]]
	    # threshold :: img float, semi-boolean, spatial

	    # At last multiplication of this with dx, dy
	    # generates the sought for h, v, removing the unwanted
	    # gradients and leaving the others untouched.

	    set h [crimp multiply $dx $threshold]
	    set v [crimp multiply $dy $threshold]
	    # h, v :: img float, spatial
	    return
	}

	proc l0smooth::Solve8 {} {
	    upvar 1 beta   beta		; # :: scalar float
	    upvar 1 result result	; # :: img float, spatial
	    upvar 1 h      h		; # :: img float, spatial
	    upvar 1 v      v		; # :: img float, spatial
	    upvar 1 f1     f1		; # :: img complex, frequency
	    upvar 1 fi     fi		; # :: img complex, frequency
	    upvar 1 cfdx   cfdx		; # :: img complex, frequency
	    upvar 1 cfdy   cfdy		; # :: img complex, frequency
	    upvar 1 denom  denom	; # :: img float, frequency

	    log \tEq/8;update

	    # Equation 8. Solve for a new result using the new h and v.
	    # NOTE: The FFTs are done in the complex domain.
	    # NOTE 2: Investigate if we can avoid real/complex/real
	    # conversions in the loop and push this before and after.

	    set fh [crimp fft forward [crimp convert 2complex $h]]
	    set fv [crimp fft forward [crimp convert 2complex $v]]
	    # fh, fv :: img complex, frequency

	    # numerator   = fi + beta * (fdx* . fh  + fdy* . fv)
	    # denominator = f1 + beta * (fdx* . fdx + fdy* . fdy)

	    # + = element-wise addition
	    # . = element-wise multiplication
	    # * = element-wise complex conjugate

	    set num [crimp add \
			 $fi \
			 [crimp convert 2complex \
			      [crimp::scale_float \
				   [crimp complex real \
					[crimp add \
					     [crimp multiply $cfdx $fh] \
					     [crimp multiply $cfdy $fv]]] \
				   $beta]]]
	    # num :: img, complex, frequency

	    set den [crimp add $f1 \
			 [crimp convert 2complex \
			      [crimp::scale_float $denom $beta]]]
	    # den :: img complex, frequency

	    set result [crimp complex real \
			    [crimp fft backward \
				 [crimp divide $num $den]]]
	    # result :: img float, spatial
	    return
	}

	proc l0smooth {image lambda {beta0 {}} {betamax 10000} {kappa 2}} {
	    # beta0, betamax, kappa => defaults.
	    # image type -> float.

	    show_image $image
	    log "Setup l=$lambda, k=$kappa, bmax=$betamax";update

	    l0smooth::Setup
	    while {$beta < $betamax} {
		log "Round $count @ $beta/$betamax"

		l0smooth::Solve12
		l0smooth::Solve8

		# Show interim results.
		show_image [crimp convert 2grey8 $result]

		# Prepare for next round.
		set beta [expr {$beta * $kappa}]
		incr count
	    }

	    log Done

	    return [crimp convert 2grey8 $result]
	}
    }
}
