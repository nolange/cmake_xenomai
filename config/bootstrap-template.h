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

/* @file bootstrap-template.h
 * @brief Template header for bootstrap code
 *
 * The bootstrap code is configurable and is supposed to
 * create a small routine that is called before other
 * automatic GCC/C++ constructors are executed,
 * as well as the regular main() routine.
 *
 * At its minimum it defines a constructor that calls
 * a xenomai_init variant,
 * and a function to retrieve the modified argv vector.
 *
 * Additionally a wrapper for the main() routine can be defined.
 * Related Macros allow to specify the name of the wrapper.
 *
 * Look into lib/boilerplate/init for usecases covering
 * shared libraries and executables usind the auto-init feature.
 *
 * Special handling for glibc can be enabled.
 * This library will pass the argv vector to constructor
 * function, thus allowing easy access to the commandline.
 *
 * Macros affecting the defined functionality:
 *
 * _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS
 *                  Use glibc constructor signature (if glibc detected)
 * _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL
 *                  *Force* glibc constructor signature on/off (value 1/0)
 * _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER
 *                  Define a main function, calling the macro expression
 * _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER
 *                  Set a weak reference to the defined main function
 * _XENOMAI_BOOTSTRAP_DSO
 *                  Should be defined when building shared libraries
 */

#include <xenomai/init.h>

/* if requested by _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS,
 * test if macros for glibc are defined and
 * define _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL accordingly */
#if !defined(_XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL) &&                    \
        defined(_XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS)
#if defined(__GLIBC__) && !defined(__UCLIBC__)
#define _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL 1
#endif
#endif

/* declare C Functions as such */
#ifdef __cplusplus
extern "C" {
#endif

void xenomai_init(int *argcp, char *const **argvp);
int xenomai_main(int argc, char *const argv[]);

int xenomai_bootstrap_getargv(int *argc, char *const **argv);

#ifdef _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER
int _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER(int argc, char *const argv[]);
#endif

#if defined(_XENOMAI_INIT_HASFETCHARGV)
#define _xenomai_init_fetchargv(a, v) xenomai_init_fetchargv((a), (v))
#else
__attribute__((unused,always_inline))
static __inline__ int _xenomai_init_fetchargv(int *argcp, char *const **argvp);
#endif

#ifndef __bootstrap_ctor
#define __bootstrap_ctor __attribute__((constructor(220)))
#endif

static struct xbootstrap_state {
	int argc;
	char *const *argv;
} early_args;

#ifdef __cplusplus
}
#endif

/* @brief get the potentially argv vector
 *
 * The xenomai init code modifies the argv vector,
 * this function allows to retrive this vector later.
 */
int xenomai_bootstrap_getargv(int *argc, char *const **argv)
{
	if (early_args.argc) {
		*argc = early_args.argc;
		*argv = early_args.argv;
		return 1;
	}
	return 0;
}

static __inline__ void _xenomai_bootstrap_setargv(int argc, char *const *argv)
{
	early_args.argc = argc;
	early_args.argv = argv;
}

static __inline__ void call_xenomai_init(int *argcp, char *const **argvp)
{
#if !defined(_XENOMAI_BOOTSTRAP_INITFLAGS) &&                                  \
        !defined(_XENOMAI_BOOTSTRAP_MODNAME)
	/* prefer previously existing functions for better backwards capability */
#ifdef _XENOMAI_BOOTSTRAP_DSO
	xenomai_init_dso(argcp, argvp);
#else
	xenomai_init(argcp, argvp);
#endif

#else
	int isDso = 0;
	unsigned long long bflags = 0;
	const char *modname = NULL;
#ifdef _XENOMAI_BOOTSTRAP_DSO
	isDso = 1;
#endif
#ifdef _XENOMAI_BOOTSTRAP_INITFLAGS
	bflags = _XENOMAI_BOOTSTRAP_INITFLAGS;
#endif
#ifdef _XENOMAI_BOOTSTRAP_MODNAME
	modname = _XENOMAI_BOOTSTRAP_MODNAME;
#endif
	xenomai_init_ext(argcp, argvp, isDso, modname, bflags);
#endif

	_xenomai_bootstrap_setargv(*argcp, *argvp);
}

/** Bootstrap: handle commandline args and call xenomai's init
 *
 * glibc calls constructors/destructors with the argv vector,
 * which is nice as this avoids some code.
 * Other C-libraries don't, and worse: define __GLIBC__
 * This probably should be an explicit opt-in
 */
#if _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL == 1
__bootstrap_ctor __attribute__((cold))
static void xenomai_bootstrap(int argc, char *const argv[],
                                               char *const envp[])
{
	(void)envp;
	call_xenomai_init(&argc, &argv);
}
#else
__bootstrap_ctor __attribute__ ((cold))
static void xenomai_bootstrap(void)
{
	char *const *argv;
	int argc;
	if (_xenomai_init_fetchargv(&argc, &argv) != 0)
		return;

	call_xenomai_init(&argc, &argv);
}
#endif

/* If requested, we define the main function,
   and weak refs */
#ifdef _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER
#ifdef _XENOMAI_BOOTSTRAP_DSO
#error "Main wrapper is not allowed for shared libraries"
#endif
int _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER(int argc, char *const argv[]);

int xenomai_main(int argc, char *const argv[])
{
#ifdef trace_me
	trace_me("xenomai_main entered");
#endif

	if (!xenomai_bootstrap_getargv(&argc, &argv)) {
		call_xenomai_init(&argc, &argv);
	}

#if defined(trace_me) && defined(__stringify)
	trace_me("xenomai_main call %s",
	         __stringify(_XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER));
#endif
	return _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER(argc, argv);
}

#ifdef _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER
int _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER(int argc, char *const argv[])
        __attribute__((alias("xenomai_main"), weak));
#endif /* ifdef _XENOMAI_BOOTSTRAP_WEAKREF_MAINWRAPPER */
#endif /* ifdef _XENOMAI_BOOTSTRAP_DEFINE_MAINWRAPPER */

/* if needed and not in the DSO, then
 * define a function for fetching the commandline arguments
 */
#if !defined(_XENOMAI_INIT_HASFETCHARGV) &&                                    \
        (!defined(_XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL) ||               \
         _XENOMAI_BOOTSTRAP_GLIBC_CONSTRUCTORS_REAL != 1)
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

/* only needed if the modecheck wrappers are active */
#ifdef _XENOMAI_BOOTSTRAP_WRAP_MALLOC
#define _WRM(x) __STD(x)
#else
#define _WRM(x) x
#endif


__attribute__((cold)) int _xenomai_init_fetchargv(int *argcp, char *const **argvp)
{
	char *arglist, *argend, *p, **v;
	ssize_t len, ret;
	int fd, n;

	len = 1024;

	for (;;) {
		fd = __STD(open("/proc/self/cmdline", O_RDONLY));
		if (fd < 0)
			return -1;

		arglist = (char*)_WRM(malloc(len));
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

	v = (char**)_WRM(malloc((n + 1) * sizeof(char *)));
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
#endif
