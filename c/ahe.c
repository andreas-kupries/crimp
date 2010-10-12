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
    int k, sum;

    if (value > 128) {
	for (k = value+1, sum = 0; k < 256; k++) {
	    sum += histogram [k];
	}
	sum = max - sum;
    } else {
	for (k = 0, sum = 0; k <= value; k++) {
	    sum += histogram [k];
	}
    }

    /* sum in [0...max].
     * sum/max in [0..1].
     * *256 to stretch into [0..255].
     */
    return 255 * sum / max;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
