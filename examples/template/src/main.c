int xenomai_bootstrap_getargv(int *argc, char *const** argv);

int main(int argc, char * const*argv)
{
#if defined(__COBALT__) || defined(__MERCURY__)
    xenomai_bootstrap_getargv(&argc, &argv);
#endif
}
