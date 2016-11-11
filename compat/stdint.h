/*
 * Local fallback for stdint.h when a system does not have it.
 * We can currently get away with an error, because right now
 * nothing actually uses the uintN_t types. This will change
 * in the future.
 */

#error "stdint.h missing - definitions needed"
