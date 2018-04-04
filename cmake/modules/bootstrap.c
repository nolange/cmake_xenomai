
#include <xenomai/init.h>

/** unlike the regular Xenomai bootstrap this does not
 *  hook the main function via wraps.
 */

int xenomai_init_getargv(int *argc, char *const** argv);

static int early_argc;

static char *const *early_argv;

int xenomai_init_getargv(int *argc, char *const** argv)
{
	if (early_argc)
	{
		*argc = early_argc;
		*argv = early_argv;
		return 1;
	}
	return 0;
}

#ifdef __BOOTSTRAP_DSO__

static inline void call_init(int *argcp, char *const **argvp)
{
	xenomai_init_dso(argcp, argvp);
}

#else

static inline void call_init(int *argcp, char *const **argvp)
{
	xenomai_init(argcp, argvp);
}

#endif /* !__BOOTSTRAP_DSO__ */

#if defined(__GLIBC__)
__bootstrap_ctor static void xenomai_bootstrap(int argc, char **argv, char **envp)
{
    /* wrong signature ?! */
    call_init(&argc, (char* const**) &argv);
    (void)envp;
    // TODO: are the argv strings replaced or modified?
    early_argc = argc;
	early_argv = argv;
}
#else
__bootstrap_ctor static void xenomai_bootstrap(void)
{
	char *arglist, *argend, *p, **v, *const *argv;
	ssize_t len, ret;
	int fd, n, argc;

	len = 1024;

	for (;;) {
		fd = __STD(open("/proc/self/cmdline", O_RDONLY));
		if (fd < 0)
			return;

		arglist = __STD(malloc(len));
		if (arglist == NULL) {
			__STD(close(fd));
			return;
		}

		ret = __STD(read(fd, arglist, len));
		__STD(close(fd));

		if (ret < 0) {
			__STD(free(arglist));
			return;
		}

		if (ret < len)
			break;

		__STD(free(arglist));
		len <<= 1;
	}

	argend = arglist + ret;
	p = arglist;
	n = 0;
	while (p < argend) {
		n++;
		p += strlen(p) + 1;
	}

	v = __STD(malloc((n + 1) * sizeof(char *)));
	if (v == NULL) {
		__STD(free(arglist));
		return;
	}

	p = arglist;
	n = 0;
	while (p < argend) {
		v[n++] = p;
		p += strlen(p) + 1;
	}

	v[n] = NULL;
	argv = v;
	argc = n;

	call_init(&argc, &argv);
	early_argc = argc;
	early_argv = argv;
}
#endif
