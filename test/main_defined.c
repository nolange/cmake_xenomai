#include "helper.h"

#if 0
int xenomai_bootstrap_getargv(int *argc, char *const** argv);

/* if built without xenomai, this fallback will be used instead */
 __attribute__((weak)) int xenomai_bootstrap_getargv(int *argc, char *const** argv)
{
	(void)argc; (void)argv;
    return 0;
}
#else
/* could aswell guard it with  !defined(__COBALT__) && !defined(__MERCURY__) */
#if !defined(__COBALT__) && !defined(__MERCURY__)
static int xenomai_bootstrap_getargv(int *argc, char *const** argv)
{
	(void)argc; (void)argv;
    return 0;
}
#else
int xenomai_bootstrap_getargv(int *argc, char *const** argv);
#endif
#endif

int main(int argc, char *const argv[], char * const envp[])
{
    xenomai_bootstrap_getargv(&argc, &argv);
    outputargs(argc, argv, envp);
    return 0;
}
