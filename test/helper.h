#include <stdio.h>

static inline void outputargs(int argc, char *const argv[], char * const envp[])
{
	int i;
	(void)envp;
	printf("main argv\n");
	for(i = 0; i < argc; ++i)
	{
		printf("%s ", argv[i]);
	}
	printf("\n");
}
