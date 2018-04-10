/*
 * The source code in this particular file is released using a dual
 * license scheme.  You can choose the licence that better fits your
 * requirements.
 *
 * -----------------------------------------------------------------------
 *
 * Copyright (C) 2017 Philippe Gerum <rpm@xenomai.org>
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *  
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * -----------------------------------------------------------------------
 *
 * Copyright (C) 2013 Philippe Gerum <rpm@xenomai.org>.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA.
 */

#include <xenomai/init.h>
/*
 * _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS      Use glibc constructor signature (if glibc detected)
 * _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL *Force* glibc constructor signature on/off (value 1/0)
 * _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER      Define a main function, calling the macro expression
 * _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER     Set a weak reference to the defined main fucntion
 * _XENOMAI_BOOTSTRAP_DSO                     Should be defined when building shared libraries
 */

#define _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS

#if !defined(_XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL) && defined(_XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS)
#if defined(__GLIBC__) && !defined(__UCLIBC__)
#define _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL 1
#endif
#endif

#ifndef __setup_section
#define __setup_section __attribute__ ((section(".text.startup.xenomai")))
#endif

static int early_argc;
static char *const *early_argv;

__setup_section int xenomai_bootstrap_getargv(int *argc, char *const** argv)
{
	if (early_argc)
	{
		*argc = early_argc;
		*argv = early_argv;
		return 1;
	}
	return 0;
}

// check if needed 
#if defined(CONFIG_XENO_VERSION_MAJOR) && _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL != 1
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

// library code for older Xenomai versions
__setup_section static int xenomai_init_fetchargv(int *argcp, char *const **argvp)
{
	char *arglist, *argend, *p, **v;
	ssize_t len, ret;
	int fd, n;

	len = 1024;

	for (;;) {
		fd = __STD(open("/proc/self/cmdline", O_RDONLY));
		if (fd < 0)
			return -1;

		arglist = __STD(malloc(len));
		if (arglist == NULL) {
			__STD(close(fd));
			return -1;
		}

		ret = __STD(read(fd, arglist, len));
		__STD(close(fd));

		if (ret < 0) {
			__STD(free(arglist));
			return -1;
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
		return -1;
	}

	p = arglist;
	n = 0;
	while (p < argend) {
		v[n++] = p;
		p += strlen(p) + 1;
	}

	v[n] = NULL;
	*argcp = n;
	*argvp = v;
	return 0;
}
#else
int xenomai_init_fetchargv(int *argcp, char *const **argvp);
#endif

/*
 * The bootstrap module object is built in two forms:
 *
 * - in static object form, to be glued to the main executable, which
 *   should include a wrapper interposing on the main() routine for
 *   auto-init purpose. Such wrapper is activated when symbol wrapping
 *   is enabled at link time (--wrap).
 *    
 * - in dynamic object form, to be included in a shared library target
 *   which enables the auto-init feature. This form should not include
 *   any wrapper to a main() routine - which does not exist - but only
 *   a constructor routine performing the inits.
 *
 * The macro __BOOTSTRAP_DSO__ tells us whether we are building the
 * bootstrap module to be glued into a dynamic shared object. If not,
 * the main() interception code should be present in the relocatable
 * object.
 */



#ifdef _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER
#ifdef _XENOMAI_BOOTSTRAP_DSO
#error "Main wrapper is not allowed for shared libraries"
#endif

#ifdef _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER
int _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER(int argc, char *const argv[])
__attribute__((alias("xenomai_main"), weak));
#endif

int _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER(int argc, char *const argv[]);

__setup_section int xenomai_main(int argc, char *const argv[])
{
	if (!early_argc)
	{
		xenomai_init(&argc, &argv);
		/* State should be identical to using a constructor function */
		early_argc = argc;
		early_argv = argv;
	}
	
	return _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER(early_argc, early_argv);
}
#endif

/**
 * glibc calls constructors/destructors with the argv vector,
 * which is nice as this avoids some code.
 * Other C-libraries don't, and worse: define __GLIBC__
 * This probably should be an explicit opt-in
 */
#if _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL == 1
__bootstrap_ctor static void xenomai_bootstrap(int argc, char *const argv[], char *const envp[])
#else
__bootstrap_ctor static void xenomai_bootstrap(void)
#endif
{
#if _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL == 1
	(void)envp;
#else
	char *const *argv;
	int argc;
	if (xenomai_init_fetchargv(&argc, &argv) != 0)
		return;
#endif

#ifdef _XENOMAI_BOOTSTRAP_DSO
	xenomai_init_dso(&argc, &argv);
#else
	xenomai_init(&argc, &argv);
#endif
	early_argc = argc;
	early_argv = argv;
}
