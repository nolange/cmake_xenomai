
Create the templates that can later be installed.

```bash
mkdir temp
./create_template.sh temp
```

To install the config files, use the script `install_cmakeconfig.sh`,
it takes a few parameters similart o configure scripts for setting the
paths. defaults should be identical to Xenomai.

Further options are needed to specify the version and bitness (sizeof(void\*)),
if those are missing the placeholders will remain.

Example for a custom configuration:

```bash
mkdir /tmp/cobalt
./install_cmakeconfig.sh --prefix=/usr/xenomai --includedir=/usr/include/xenomai --version 3.0.4 --bitness 8 -- /tmp/cobalt
```


Example for debians defaults;

```bash
mkdir /tmp/mercury
./install_cmakeconfig.sh --with-core=mercury --version 3.0.4 --bitness 8 -- /tmp/mercury
```
