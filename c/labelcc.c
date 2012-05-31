/*
 * labelcc.c --
 *
 *	Code for connected component labeling of CRIMP images.
 *
 * Copyright (c) 2011 by Kevin B. Kenny.
 *
 * See the file "license.terms" for information on usage and redistribution of
 * this file, and for a DISCLAIMER OF ALL WARRANTIES.
 *
 *-----------------------------------------------------------------------------
 */

#include <memory.h>
#include <stdlib.h>
#include <tcl.h>

#include <crimp_core/crimp_coreDecls.h>

/*
 * FIXME:
 * 
 * Type of a CRIMP grey32 image - Andreas means to change this to 'unsigned'
 */

#define RANK_TYPE unsigned

/* Static procedures defined in this file */

static void UnionIfNeeded(crimp_image*, size_t*, RANK_TYPE*, size_t, size_t);
static int Find(size_t*, size_t);

/*
 *-----------------------------------------------------------------------------
 *
 * UnionIfNeeded --
 *
 *	Calculates the union of two sets in a disjoint-subsets partition.
 *	Specialized to unite two sets that correspond to adjacent image
 *	pixels, if and only if the pixel values are equal.
 *
 * Results:
 *	None.
 *
 * Side effects:
 *	Updates the 'parent' and 'rank' arrays to reflect set membership.
 *
 * This function gives the 'Union' part of the 'Union Find' algorithm, well 
 * known in the computing folklore and apparently described first by
 * B.A. Galler and M.J. Fisher: "An improved equivalence algorithm."
 * _J. ACM_ 7:5 (May, 1964), pp. 301-303. doi:10.1145/364099.364331
 * http://portal.acm.org/citation.cfm?doid=364099.364331
 *
 * See also R.E. Tarjan, "Efficiency of a good but not linear set union 
 * algorithm." _J. ACM_ 22:2 (April, 1975) pp. 215-225 doi:10.1145/321879.321884
 * http://portal.acm.org/citation.cfm?doid=321879.321884 for a thorough
 * analysis of the algorithm's performance.
 *
 *-----------------------------------------------------------------------------
 */

static void
UnionIfNeeded(
    crimp_image* imagePtr,	/* Image being processed */
    size_t* parent,		/* Array of parent links */
    RANK_TYPE* rank,		/* Array of subset ranks */
    size_t x, 			/* Index of a pixel in the first subset */
    size_t y			/* Index of a pixel in the second subset */
) {
    int xRoot;
    int yRoot;			/* Indices of the unique exemplars of the
				 * two subsets */

    /* Return if the pixels differ; the sets should not be merged. */

    int esize = SZ(imagePtr);
    if (memcmp(imagePtr->pixel + x*esize, imagePtr->pixel + y*esize, esize)) {
	return;
    }

    /* Find the unique exemplars of the two subsets being merged */

    xRoot = Find(parent, x);
    yRoot = Find(parent, y);
    if (xRoot == yRoot) {
	/* 
	 * Pixels are already in the same subset 
	 */
	return;
    }

    /* Merge the subsets, updating parent links and ranks */

    if (rank[xRoot] < rank[yRoot]) {
	parent[xRoot] = yRoot;
    } else {
	parent[yRoot] = xRoot;
	if (rank[xRoot] == rank[yRoot]) {
	    ++rank[xRoot];
	}
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * Find --
 *
 *	Find the unique exemplar of the subset to which a given pixel belongs
 *	in a disjoint-subsets partition.
 *
 * Results:
 *	Returns the index of the unique exemplar.
 *
 * Side effects:
 *	Compresses the path on which the exemplar was reached.
 *
 * See 'UnionIfNecessary' for references on the algorithm.
 *
 *-----------------------------------------------------------------------------
 */
static int
Find(
    size_t* parent,
    size_t x
) {
    if (parent[x] == x) {
	return x;
    } else {
	return (parent[x] = Find(parent, parent[x]));
    }
}

/*
 *-----------------------------------------------------------------------------
 *
 * LabelConnectedComponents --
 *
 *	Develops a connected-components labeling for a source image,
 *
 * Results:
 *	Returns the labeling as an int32 image whose pixel values are
 *	component numbers.
 *
 * Side effects:
 *	Allocates memory for the result; the caller is responsible for using
 *	crimp_del when the result is no longer required.
 *
 *-----------------------------------------------------------------------------
 */

crimp_image*
crimp_label_connected_components (
    int eightconnected,		/* Flag == 1 to return 8-connected
				 * components, 0 to use 4-connected components.
				 * 4-connected is recommended; it is both faster
				 * and generates more compact components
				 * (at the expense of generating more of 
				 * them). */
    const void* bgValue,
				/* Pointer to the pixel value that will be
				 * used as background. All background pixels
				 * are coalesced into a single component.
				 * NULL means not to use a background value. */
    crimp_image* imagePtr	/* Input image to segment. */
) {
    int height = crimp_h(imagePtr);	/* Height of the image */
    int width = crimp_w(imagePtr);	/* Width of the image */
    int locx = crimp_x(imagePtr);	/* Location of the image */
    int locy = crimp_y(imagePtr);	/* Location of the image */
    int esize = SZ(imagePtr);	/* Size of a pixel value */
    int wm1 = width - 1;
    int wp1 = width + 1;
    size_t area = (size_t)width * (size_t)height;
				/* Area of the image in pixels */
    size_t* parent = (size_t*) ckalloc(area * sizeof(size_t));
				/* Parent link data structure for
				 * UNION-FIND partition */
    crimp_image* result = crimp_new_grey32_at (locx, locy, width, height);
				/* Result image containing subset ranks
				 * during the UNION-FIND calculation and
				 * component numbers during the component
				 * numbering pass. */
    RANK_TYPE* rank = (RANK_TYPE*) result->pixel;
				/* Pixel array for the result image */
    int i, j;			/* Row and column indices */
    size_t p;			/* Pixel index */

    /* 
     * First pass: Connect every pixel with its neighbours to the
     *             north and west (4-connected regions) or to the
     *             NW, N, NE and W (8-connected regions). 
     */

    /* 
     * Top row - do only neighbour to the west. First pixel has no
     * neigbours. 
     */

    rank[0] = 0;
    parent[0] = 0;
    p = 1;       
    for (j = 1; j < width; ++j) {
	rank[p] = 0;
	parent[p] = p;
	UnionIfNeeded(imagePtr, parent, rank, p-1, p);
	++p;
    }
    if (eightconnected) {

	/* 
	 * 8-connected regions, rows other than top. Leftmost pixel
	 * has only N and NE neighbours.
	 */

	for (i = 1; i < height; ++i) {
	    rank[p] = 0; 
	    parent[p] = p;
	    UnionIfNeeded(imagePtr, parent, rank, p-width, p);
	    UnionIfNeeded(imagePtr, parent, rank, p-wm1, p);
	    ++p;

	    /* 
	     * Interior pixels have all four neighbours
	     */

	    for (j = 1; j < wm1; ++j) {
		rank[p] = 0;
		parent[p] = p;
		UnionIfNeeded(imagePtr, parent, rank, p-wp1, p);
		UnionIfNeeded(imagePtr, parent, rank, p-width, p);
		UnionIfNeeded(imagePtr, parent, rank, p-wm1, p);
		UnionIfNeeded(imagePtr, parent, rank, p-1, p);
		++p;
	    }

	    /*
	     * Rightmost pixel lacks a NE neighbour
	     */

	    rank[p] = 0;
	    parent[p] = p;
	    UnionIfNeeded(imagePtr, parent, rank, p-wp1, p);
	    UnionIfNeeded(imagePtr, parent, rank, p-width, p);
	    UnionIfNeeded(imagePtr, parent, rank, p-1, p);
	    ++p;
	}

    } else {

	/* 
	 * 4-connected region, rows other than the top. Leftmost pixel
	 * has only a N neighbour.
	 */
	for (i = 1; i < height; ++i) {
	    rank[p] = 0;
	    parent[p] = p;
	    UnionIfNeeded(imagePtr, parent, rank, p-width, p);
	    ++p;

 	    /*
	     * All other pixels have N and W neighbours.
	     */

	    for (j = 1; j < width; ++j) {
		rank[p] = 0;
		parent[p] = p;
		UnionIfNeeded(imagePtr, parent, rank, p-width, p);
		UnionIfNeeded(imagePtr, parent, rank, p-1, p);
		++p;
	    }
	}
    }
    if (p != area) {
	Tcl_Panic("p is %ld should be %ld\n", p, area);
    }

    /*
     * Second pass.  Assign labels, reusing the 'rank' array to
     * hold them.
     */

    memset(rank, 0, area * sizeof(*rank));
    j = 1;
    for (p = 0; p < area; ++p) {
	if (!bgValue || memcmp(imagePtr->pixel + p*esize, bgValue, esize)) {
	    i = Find(parent, p);
	    if (rank[i] == 0) {
		rank[i] = j++;
	    } 
	    rank[p] = rank[i];
	} else {
	    rank[p] = 0;
	}
    }

    ckfree((char*)parent);
    return result;
}

