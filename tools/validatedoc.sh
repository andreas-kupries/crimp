#!/bin/sh
# tools
# % generate the embedded documentation.
# % the images required by it as well.

# 1. math formulas               -> png	/requires mimetex + imagemagick convert.
# 2. tklib/diagram based figures -> png	/requires tklib dia application.
# 3. html + images from the doctools
# 4. nroff from the doctools

(   cd doc

    echo ___ VALIDATE _________
    dtplite validate .
)

exit
