/*
 * CRIMP :: AHE Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <ahe.h>

/*
 * Definitions :: Core.
 */

int
crimp_ahe_transfer (int histogram [256], int value, int max)
{
    /*
     * (0) max = number of pixels in the histogram, for AHE this is (2r+1)^2.
     * ==> max = sum (i,histogram[i]).
     *
     * (1) CDF(value) =       sum (k <= value,histogram[k]) <a>
     *                = max - sum (k >  value,histogram[k]) <b>
     *
     *     max = sum (k,histogram[k])
     *         = sum (k<=value,histogram[k]) + sum (k>value,histogram[k]). 
     *
     * (2) sum = CDF(value) >=0, <= max
     * ==> sum         in [0-max]
     * ==> sum/max     in [0-1]
     * ==> 255*sum/max in [0-255]. (Stretched, proper pixel value).
     */

    int k, sum;

    if (value > 128) {
	/* <1b> */

	for (k = value+1, sum = 0; k < 256; k++) {
	    sum += histogram [k];
	}
	sum = max - sum;
    } else {
	/* <1a> */

	for (k = 0, sum = 0; k <= value; k++) {
	    sum += histogram [k];
	}
    }

    /* (2) */
    return 255 * sum / max;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
