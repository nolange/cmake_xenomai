# CMake support for Xenomai

This project aims to make the Xenomai libraries easily accessible with CMake,
and hopefully in the longterm be added to upstream CMake.

# Concepts

the use of the Module is aimed to be largely optional, means projects should be able to
buildable without Xenomai with minimal (or no) changes.
This has the effect that potentially required flags or libraries for Xenomai aren't provided automatically,
to leave the full flexibility to the user. For example the Thread support has to be explicitely stated and linking to
`-librt` is a good idea, but both are not absolutely necessary for every project so they are left out.

The integration aims to be "modern CMake", means you call `find_package(Xenomai)`, which defines import libraries you can
use to describe dependencies. Use of variables is not recommended, and exisiting variables might be removed at any time.

An example project would look like this:

```cmake
cmake_minimum_required(VERSION 3.5 FATAL_ERROR)

# Set the path so FindXenomai.cmake can be resolved
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules")

project(myproject VERSION 0.1)

# most applications will need threads
set(THREADS_PREFER_PTHREAD_FLAG true)
find_package(Threads REQUIRED)
# skip the modecheck library (only cobalt kernels)
set(XENOMAI_SKIP_MODECHECK true)
# and we require Xenomai 3 or higher
find_package(Xenomai 3.0 REQUIRED)

add_executable(myexec
	src/myexec.c
# this is the xenomai bootstrap, likely is going to change
	src/bootstrap.c
)

# use Cobalt without Posix Wrappings
target_link_libraries(myexec PRIVATE
	Xenomai::Cobalt Xenomai::ModeChk Threads::Threads rt
)

add_executable(anotherexec
# this one is smart enough to call xenomai_init if available + necessary
	src/another_withownbootstrap.c
)

# without xenomai, its just built as regular posix
# with xenomai, it can use Mercury or Cobalt
if (XENOMAI_FOUND)
target_link_libraries(anotherexec PRIVATE
	Xenomai::Posix
)
endif()

# These are always needed, cant depend on Xenomai pulling the dependencies in
# (and it does not for that reason)
target_link_libraries(anotherexec PRIVATE
	Threads::Threads rt
)	
```

Configuration allows specifying a toolchain/build environment. This is an real example using a [Buildroot](https://buildroot.org/) installation:

```bash
mkdir /tmp/build; cd /tmp/build
cmake -DCMAKE_TOOLCHAIN_FILE=$HOME/buildroot/host/share/buildroot/toolchainfile.cmake  $HOME/code/xeno_cmake/examples/alchemy
make -j4 VERBOSE=1
```


# bootstrapping

"bootstrapping" is the method to automatically initialise an Xenomai Application,
by interposing an `xenomai_init` and passing it the plain commandline argument.
the original `main` is replaced with linker flags and then called with preprocessed
commandline arguments.

some concepts map rather badly to CMake (for example there is no way to cleanly introduce compiled object files),
and is lacking some flexibility. The obvious upside is that POSIX Applications can be compiled without touching the code.

Currently there is no equivalent in this project.

The aim is to require just a few modifications around the `main` routine, this explicit
modification would allow dropping of some intransparent linker-remapping and some customization/variants
for the boostrap code

-   distribute (install) the boostrap as source.
    this is more flexible, especially in regards to different compilers + settings
-   either require the application to rename the main routine to something else (predefined name).
-   or do so in a hacky way by defining main as macro.


## More detailed description

The boostrapping code does multiple tasks

-   parse parameters from the commandline, create a new `reduced argv` with those options removed
-   setup Xenomai subsystems (potentially depending on the parameters)
-   promote the main thread to realtime (otherwise most cobalt calls will fail)
-   a wrapper that interposes on the ragular `main` function and call it with the `reduced argv`

The first three points can be called the `early initialisation` happen relatively early with gcc's attribute `constructor(220)`, see the file `include/boilerplate/setup.h`.
Specifically it runs before normal (non-priority) `constructor` functions and C++ global constructors, which thus could depend on Xenomai already been initialised. A fully explicit call to `xenomai_init` from the `main` function would have the downside of not supporting these constructs.

The wrapping of the main function is (perhaps just subjectively) pretty complicated. My opionion (nolange) would be to
easily be able to add the `early initialisation` to a project, while not providing an intransparent option for wrapping the main function.

some possible alternatives for the `main` wrap follow.

Variant A "Linkersymbol"

```c
int xenomai_init_getargv(int *argc, char *const** argv);

 __attribute__((weak)) int xenomai_init_getargv(int *argc, char *const** argv)
{
	return 0;

}
int main(int argc, char *const argv[])
{
	xenomai_init_getargv(&argc, &argv);
}
```

Variant B "Macro Guard"

```c
int xenomai_init_getargv(int *argc, char *const** argv);

int main(int argc, char *const argv[])
{
#if defined(__COBALT__) || defined(__MERCURY__)
	xenomai_init_getargv(&argc, &argv);
#endif
}
```

Variant C "Dont Care"

```c
int main(int argc, char *const argv[])
{
	/* argv might have arguments that were already consumed in early initialisation */
}
```





# State

Currently WIP, mostly tested is the Cobalt Library. The examples are building but likely wont work due to
yet unresolved and missing "bootstrap" inititialisation

# Licenses

Sources genuine to this project are covered by the 3-Clause-BSD (identical to CMake),
while the examples are lifted from Xenomai itself and are under GPL 2 unless noted otherwise.
