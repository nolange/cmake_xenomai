#include "helper.h"

int __real_main(int argc, char *const argv[], char * const envp[])
{
	outputargs(argc, argv, envp);

    return 0;
}

/* if built without xenomai, define an alias to __wrap_main */
#if !defined(__COBALT__) && !defined(__MERCURY__)
__attribute__((alias("__real_main")))
int main(int argc, char *const argv[], char * const envp[]);
#endif
