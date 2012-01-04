#!/bin/sh
# tools
# % generate the embedded documentation.

# 1. html + images from the doctools
# 2. nroff from the doctools

(   cd doc
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
exit
echo ___ MAN /show _________
less embedded/man/files/crimp.n

exit
