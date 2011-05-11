long int
lrint (double x)
{
  return (long int) (x < 0.0
		     ? ceil (x - 0.5)
		     : floor(x + 0.5));
}
