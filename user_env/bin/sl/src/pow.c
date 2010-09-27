#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>

void Usage(const char* prog)
{
	printf("       Usage: %s number exponent\n", prog);
}

int main(int argc, char** argv)
{
	if (argc < 3)
	{
		Usage(argv[0]);
		return 1;
	}

	for (int i = 1; i < 3; i++)
	{
		if (!isdigit(argv[i][0]))
		{
			Usage(argv[0]);
			return 1;
		}
	}
	
	printf("%f\n", pow(atof(argv[1]), atof(argv[2])));

	return 0;
}
