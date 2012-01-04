#!/bin/sh
# tools
# % generate the figures for the embedded documentation.

# math formulas -> png
# requires mimetex + imagemagick's convert.

cd doc/figures/math
echo ___ MATH _________

rm -rf *.png

for figure in *.txt ; do
    echo $figure

    mimetex -f $figure -e $$.gif
    convert $$.gif $(basename $figure .txt).png
    rm $$.gif
done


exit
