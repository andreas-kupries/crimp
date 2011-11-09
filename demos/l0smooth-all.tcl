def op_l0smoothing_rgb_hsv {
    label {L0 Smoothing, RGB + HSV}
    setup_image {
	showsmooth [base]
    }
    setup {
	proc showsmooth {i} {
	    # Do the smoothing separately on each channel. While this
	    # is not how the original performs the operation it is
	    # easier to implement. I will have to see how much this
	    # affects the result.

	    set i [crimp convert 2rgb $i]
	    set h [crimp convert 2hsv $i]

	    set res {}
	    foreach c [crimp split $i] {
		lappend res [l0smooth $c 0.005]
	    }
	    set r [crimp join 2rgb {*}$res]

	    set res {}
	    foreach c [crimp split $h] {
		lappend res [l0smooth $c 0.005]
	    }
	    set h [crimp convert 2rgb [crimp join 2hsv {*}$res]]

	    show_image [crimp montage vertical \
			    $r $h $i]
	    return
	}

	namespace eval l0smooth {
	    variable DX [crimp kernel fpmake {{ 0  1  -1}} 0]
	    variable DY [crimp kernel transpose $DX]
	    # DX, DY :: float, convolution kernel, spatial

	    variable DXI [crimp read tcl float {{1   -1}}]
	    variable DYI [crimp read tcl float {{1} {-1}}]
	    # DXI, DYI :: float, convolution kernel, spatial, FFT inputs.

	    variable tofloat [expr {1./255}]
	    variable toint   255.0
	}

	proc l0smooth::Setup {} {
	    variable DX
	    variable DY
	    variable DXI
	    variable DYI
	    variable tofloat
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

	    set image [crimp::scale_float \
			   [crimp convert 2float $image] $tofloat]
	    # image :: img float, range [0...1]

	    # loop initialization
	    set result $image
	    set beta   $beta0
	    set count  0

	    lassign [crimp dimensions $image] w h

	    # Constant parts of the loop moved upfront.

	    set f1 [crimp convert 2complex [crimp blank float $w $h 1.0]]
	    # f1 :: img complex, frequency

	    # This is the FFT of the delta function. That is, a single
	    # 1 in the top left corner.  Interestingly, the result is
	    # an image with an 1 in all pixels. So we spare us the FFT
	    # and generate this directly.

	    set fi [crimp fft forward [crimp convert 2complex $image]]
	    # fi :: img complex, frequency

	    # FFT of the convolution kernels ...
	    # It is easier to construct them directly than to pull the
	    # images out of the kernels, and then shift them properly
	    # during the expansion. (The center 1 must be placed in
	    # the top left corner).

	    # We assume that DX/DY are smaller than the image in all
	    # respects. We will be in trouble should the input image
	    # get smaller than 3x3.

	    log dxi=[crimp::dimensions $DXI]
	    log dyi=[crimp::dimensions $DYI]

	    set dx [crimp expand const $DXI 0 0 [expr {$w-2}] [expr {$h-1}] 0.0]
	    set dy [crimp expand const $DYI 0 0 [expr {$w-1}] [expr {$h-2}] 0.0]
	    # dx, dy :: img float, spatial

	    log dx=[crimp::dimensions $dx]
	    log dy=[crimp::dimensions $dy]

	    set fdx [crimp fft forward [crimp convert 2complex $dx]]
	    set fdy [crimp fft forward [crimp convert 2complex $dy]]
	    # fdx, fdy :: img complex, frequency

	    # Conjugates. See Solve8.
	    set cfdx [crimp complex conjugate $fdx]
	    set cfdy [crimp complex conjugate $fdy]
	    # cfdx, cfdy :: img complex, frequency

	    # The main part of the denominator used in Solve8 uses
	    # multiplication of numbers with their own complex
	    # conjugate (fdX, cfdX). That comes down to the squared
	    # magnitude, which we can compute easier. We pre-convert
	    # the result to complex as that allows us to avoid a few
	    # casts (conversions) later in the loop.

 	    set denom [crimp convert 2complex \
			   [crimp add \
				[crimp::sqmagnitude_fpcomplex $fdx] \
				[crimp::sqmagnitude_fpcomplex $fdy]]]
	    # denom :: img complex, frequency
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

	    # At last, multiplication of this with dx, dy
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
	    #                    denom = ~~~~~~~~~~~~~~~~~~~~~~~

	    # + = element-wise addition
	    # . = element-wise multiplication
	    # * = element-wise complex conjugate

	    set numer [crimp add \
			   [crimp multiply $cfdx $fh] \
			   [crimp multiply $cfdy $fv]]

	    set num [crimp add $fi [crimp::scale_fpcomplex $numer $beta]]
	    set den [crimp add $f1 [crimp::scale_fpcomplex $denom $beta]]
	    # num :: img complex, frequency
	    # den :: img complex, frequency

	    set result [crimp complex real \
			    [crimp fft backward \
				 [crimp divide $num $den]]]
	    # result :: img float, spatial
	    return
	}

	proc l0smooth {image lambda {beta0 {}} {betamax 10000} {kappa 2}} {
	    variable l0smooth::toint

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
		show_image [crimp convert 2grey8 \
				[crimp::scale_float $result $toint]]

		# Prepare for next round.
		set beta [expr {$beta * $kappa}]
		incr count
	    }

	    log Done

	    return [crimp convert 2grey8 \
			[crimp::scale_float $result $toint]]
	}
    }
}
