def op_alpha_blend {
    label Blend
    setup {
	set ::X 255
	scale .s \
	    -variable ::X \
	    -from 0 \
	    -to 255 \
	    -orient vertical \
	    -command [list ::apply {{alpha} {

		# We are blending with a uniform black background.
		# This is actually a 'darkening' op, where alpha going
		# down to 0 makes the image darker until we reach
		# black.

		set blend [crimp blend [base] [crimp blank rgba 800 600 0 0 0 255] $alpha]
		show_image $blend
		return

		# Blending two regular images in this manner generates
		# weird intermediate colors ... I wonder if it would
		# work better in HSV space.

		# The problem is that we are interpolating colors, at
		# each pixel, and in RGB the interpolation generates
		# colors which really not much to do with the end
		# points. non-linear trajectory through the
		# cube. Whereas in HSV, this may be more linear. And
		# if not, then wht about the CIE spaces ?

		set blend [crimp blend [base 0] [base 1] $alpha]
		show_image $blend
		return

		# Blending white attempt, not really working.

		set blend [crimp setalpha \
			       [crimp blend [base] [crimp blank rgba 800 600 255 255 255 255] $alpha] \
			       [crimp blank grey8 800 600 255]]
		show_image $blend
		return

	    }}]
	extendgui .s
    }
    shutdown {
	destroy .s
	unset ::X
    }
}
