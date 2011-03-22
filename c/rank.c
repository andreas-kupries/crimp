/*
 * CRIMP :: Rank Definitions (Implementation).
 * (C) 2010.
 */

/*
 * Import declarations.
 */

#include <rank.h>

/*
 * Definitions :: Core.
 */

int
crimp_rank (int histogram [256], int percentile, int max)
{
    int k, sum, cut;

    cut = (max*percentile)/10000;

    for (k = 0, sum = 0; k < 256; k++) {
	sum += histogram [k];
	if (sum > cut) { return k; }
    }
    return 255;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
