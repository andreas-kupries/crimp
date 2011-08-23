/*
 * CRIMP :: Buffer Definitions (Implementation).
 * (C) 2011.
 */

/*
 * Import declarations.
 */

#include <coreInt.h>

/*
 * Definitions :: Core.
 */

void
crimp_buf_init (crimp_buffer* buf, Tcl_Obj* data)
{
    buf->buf      = Tcl_GetByteArrayFromObj(data, &buf->length);
    buf->here     = buf->buf;
    buf->sentinel = buf->buf + buf->length;
}

int
crimp_buf_has (crimp_buffer* buf, int n)
{
    return n <= (buf->sentinel - buf->here);
}

int
crimp_buf_size (crimp_buffer* buf)
{
    return buf->length;
}

int
crimp_buf_tell (crimp_buffer* buf)
{
    return (buf->here - buf->buf);
}

int
crimp_buf_check (crimp_buffer* buf, int location)
{
    return (0 <= location) && (location < buf->length);
}

void
crimp_buf_moveto (crimp_buffer* buf, int location)
{
    CRIMP_ASSERT_BOUNDS (location, buf->length);

    buf->here = buf->buf + location;
}

void
crimp_buf_skip (crimp_buffer* buf, int n)
{
    if (n > 0) {
	CRIMP_ASSERT_BOUNDS (n-1,(buf->sentinel - buf->here));
    } else if (n < 0) {
	CRIMP_ASSERT_BOUNDS ((buf->here - buf->buf),-n+1);
    } else return;

    buf->here += n;
}

void
crimp_buf_align (crimp_buffer* buf, int n)
{
   int loc = (buf->here - buf->buf);
   int off = loc % n;

   if (!off) return;

   crimp_buf_skip (buf, n-off);
}

void
crimp_buf_alignr (crimp_buffer* buf, int base, int n)
{
   int loc = (buf->here - buf->buf) - base;
   int off = loc % n;

   if (!off) return;

   crimp_buf_skip (buf, n-off);
}

int
crimp_buf_match (crimp_buffer* buf, int n, char* str)
{
    if (n < 0) {
	n = strlen (str);
    }

    CRIMP_ASSERT_BOUNDS (n,(buf->sentinel - buf->here));

    int res;

    if (strncmp(buf->here, (unsigned char*) str, n) != 0) {
	return 0;
    }

    buf->here += n;
    return 1;
}

void
crimp_buf_read_uint8 (crimp_buffer* buf, unsigned int* res)
{
    CRIMP_ASSERT_BOUNDS (0,(buf->sentinel - buf->here));

    *res = buf->here[0];

    buf->here ++;
}

void
crimp_buf_read_uint16le (crimp_buffer* buf, unsigned int* res)
{
    CRIMP_ASSERT_BOUNDS (1,(buf->sentinel - buf->here));

    *res = (buf->here[0] |
	    buf->here[1] << 8);

    buf->here += 2;
}

void
crimp_buf_read_uint32le (crimp_buffer* buf, unsigned int* res)
{
    CRIMP_ASSERT_BOUNDS (3,(buf->sentinel - buf->here));

    *res = (buf->here[0] |
	    buf->here[1] << 8 |
	    buf->here[2] << 16 |
	    buf->here[3] << 24);

    buf->here += 4;
}

void
crimp_buf_read_uint16be (crimp_buffer* buf, unsigned int* res)
{
    CRIMP_ASSERT_BOUNDS (1,(buf->sentinel - buf->here));

    *res = (buf->here[1] |
	    buf->here[0] << 8);

    buf->here += 2;
}

void
crimp_buf_read_uint32be (crimp_buffer* buf, unsigned int* res)
{
    CRIMP_ASSERT_BOUNDS (3,(buf->sentinel - buf->here));

    *res = (buf->here[3] |
	    buf->here[2] << 8 |
	    buf->here[1] << 16 |
	    buf->here[0] << 24);

    buf->here += 4;
}

void
crimp_buf_read_int8 (crimp_buffer* buf, int* res)
{
    CRIMP_ASSERT_BOUNDS (0,(buf->sentinel - buf->here));

    *res = buf->here[0];

    buf->here ++;
}

void
crimp_buf_read_int16le (crimp_buffer* buf, int* res)
{
    CRIMP_ASSERT_BOUNDS (1,(buf->sentinel - buf->here));

    *res = (buf->here[0] |
	    buf->here[1] << 8);

    buf->here += 2;
}

void
crimp_buf_read_int32le (crimp_buffer* buf, int* res)
{
    CRIMP_ASSERT_BOUNDS (3,(buf->sentinel - buf->here));

    *res = (buf->here[0] |
	    buf->here[1] << 8 |
	    buf->here[2] << 16 |
	    buf->here[3] << 24);

    buf->here += 4;
}

void
crimp_buf_read_int16be (crimp_buffer* buf, int* res)
{
    CRIMP_ASSERT_BOUNDS (1,(buf->sentinel - buf->here));

    *res = (buf->here[1] |
	    buf->here[0] << 8);

    buf->here += 2;
}

void
crimp_buf_read_int32be (crimp_buffer* buf, int* res)
{
    CRIMP_ASSERT_BOUNDS (3,(buf->sentinel - buf->here));

    *res = (buf->here[3] |
	    buf->here[2] << 8 |
	    buf->here[1] << 16 |
	    buf->here[0] << 24);

    buf->here += 4;
}

/*
 * Local Variables:
 * mode: c
 * c-basic-offset: 4
 * fill-column: 78
 * End:
 */
