#include "stdio.h"
#include "stdlib.h"

int main(int argc, char** argv)
{
	if (argc < 2)
	{
		return 1;
	}
	
	printf("%f", atof(argv[1]) * atof(argv[2]));

	return 0;
}
