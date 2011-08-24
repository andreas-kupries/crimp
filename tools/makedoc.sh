#!/bin/sh
# tools
# % generate the embedded documentation.
# % the images required by it as well.

# 1. math formulas               -> png	/requires mimetex + imagemagick convert.
# 2. tklib/diagram based figures -> png	/requires tklib dia application.
# 3. html + images from the doctools
# 4. nroff from the doctools

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

    echo ___ MAN _________
    rm -rf     ../embedded/man
    mkdir      ../embedded/man
    dtplite -ext n -o ../embedded/man nroff .

    echo ___ WWW _________
    rm -rf     ../embedded/www
    mkdir      ../embedded/www
    dtplite -o ../embedded/www -merge html  .
    dtplite -o ../embedded/www -merge html  .
)

echo ___ MAN /show _________
less embedded/man/files/crimp.n

exit
