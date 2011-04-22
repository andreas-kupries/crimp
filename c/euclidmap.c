#include <float.h>
#include <math.h>
#include <tcl.h>

/* 
 * VERYFAR is a quantity greater than the squared Euclidean distance
 * between any two points in an image. We can't use Infinity for VERYFAR
 * without introducing special cases in the main loop, but FLT_MAX works
 * nicely.  VERYFAR should also be used as the 'infinity' when constructing
 * indicator functions.
 */

#define VERYFAR FLT_MAX

/*
 *-----------------------------------------------------------------------------
 *
 * EuclideanDistanceMap1D --
 *
 *	Compute the Euclidean distance map in one dimension, given as input
 *	a distance function orthogonal to that dimension (or an indicator
 *	function).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Returns the distance function in the 'dist' array.
 *
 * Input and output arrays may not occupy the same memory.
 *
 *-----------------------------------------------------------------------------
 */

void
EuclideanDistanceMap1D(
    int n,			/* Size of the array being analyzed */
    const float* f,		/* INPUT: Cost function (squared distance)
				 * for reaching points along the axis being
				 * analyzed. */
    int stride,			/* Stride of the array being analyzed */
    float* dist			/* OUTPUT: Distance map */
) {
    int* v = (int*) ckalloc(n * sizeof(int));
				/* Vertices of the parabolae that give
				 * the distance to each point */
    float* z = (float*) ckalloc((n+1) * sizeof(float));
				/* z[n] is the x-coordinate of the intersection
				 * of the nth parabola with the (n-1)st */
    int k;			/* Index of the current parabola */
    int vertex;			/* The current parabola's vertex is
				 * (vertex, f[vertex]) */
    float s;			/* Intersection point of the current
				 * parabola with the horizon */
    int q;			/* Index of the point being examined */

    /* Pass 1: For each point in the input, plot a parabola giving the
     *         distance function for locations closest to that point.
     *         Find the intersections of the parabolae that are local
     *	       mimina of the overall cost function, and put each
     *	       successive local minimum's vertex in v and the
     *	       x-coordinates of the intersections in z.
     *
     * First parabola has its vertex at the first input point, and the
     * inital state is that the first parabola is in use over the entire
     * line.
     */

    z[0] = -VERYFAR;
    z[1] = VERYFAR;
    v[0] = 0;
    k = 0;
    s = VERYFAR;

    /* Iterate over the remaining points. */

    for (q = 1; q < n; ++q) {

	/* 
	 * Iterate backwards over the parabolae in the current set and plot
	 * their intersections with the current point's parabola. Quit when we
	 * find one that intersects the current horizon. 
	 */

	while (1) {
	    vertex = v[k];
	    s = 0.5f * ((f[q * stride] - f[vertex * stride]) / (q - vertex) 
			+ q + vertex);
	    if (s > z[k]) {
		break;
	    }
	    --k;
	}

	/*
	 * Found an intersection. Stack it.
	 */

	++k;
	v[k] = q;
	z[k] = s;
	z[k+1] = VERYFAR;
    }

    /*
     * Pass 2. Go through the points from left to right, keeping track of
     * which parabola is on the horizon. Label the points with the distance
     * function.
     */

    k = 0;
    for (q = 0; q < n; ++q) {
	int dx;
	while (z[k+1] < q) {
	    ++k;
	}
	dx = (q - v[k]);
	dist[q*stride] = dx*dx + f[v[k] * stride];
    }

    ckfree((char*) z);
    ckfree((char*) v);

}

/*
 *-----------------------------------------------------------------------------
 *
 * EuclideanDistanceMap2D --
 *
 *	Compute the Euclidean distance map in two dimensions, given as input
 *	a distance function orthogonal to that dimension (or an indicator
 *	function).
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Returns the distance function in the 'dist' array.
 *	Input and output arrays may occupy the same memory,
 *
 *-----------------------------------------------------------------------------
 */

void
EuclideanDistanceMap2D(
    int height,			/* Height of the function */
    int width,			/* Width of the function */
    const float* f,		/* Input indicator function (or distance map) */
    float* dist			/* Output distance function */
) {
    int i;
    size_t area = (size_t) width * (size_t) height;
    float* tempImage = (float*) ckalloc(area * sizeof(float));

    /* Distance-map the rows */

    for (i = 0; i < height; ++i) {
	EuclideanDistanceMap1D(width, f + i * (size_t)width, 1,
			       tempImage + i * (size_t) width);
    }

    /* Distance-map the columns */

    for (i = 0; i < width; ++i) {
	EuclideanDistanceMap1D(height, tempImage + i, width, dist + i);
    }
}
