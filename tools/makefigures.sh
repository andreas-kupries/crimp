#!/bin/sh
# tools
# % generate the figures for the embedded documentation.

# 1. math formulas               -> png	/requires mimetex + imagemagick convert.
# 2. tklib/diagram based figures -> png	/requires tklib dia application.

(   cd doc/figures
    echo ___ DIA _________
    dia convert -t -o . png *.dia
)

exit
