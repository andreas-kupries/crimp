#!/bin/sh
# tools
# % generate the figures for the embedded documentation.

# 1. math formulas               -> png	/requires mimetex + imagemagick convert.
# 2. tklib/diagram based figures -> png	/requires tklib dia application.

(   cd doc
    (   cd figures
	(   cd math
	    echo ___ MATH _________
	    rm -rf *.png
	    for figure in *.txt ; do
		echo $figure

		mimetex -f $figure -e $$.gif
		convert $$.gif $(basename $figure .txt).png
		rm $$.gif
	    done
	)
	echo ___ DIA _________
	dia convert -t -o . png *.dia
    )
)

exit
