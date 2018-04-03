#include <xenomai/init.h>

#define DEC(n)                   \
  ('0' + (((n) / 10000000)%10)), \
  ('0' + (((n) / 1000000)%10)),  \
  ('0' + (((n) / 100000)%10)),   \
  ('0' + (((n) / 10000)%10)),    \
  ('0' + (((n) / 1000)%10)),     \
  ('0' + (((n) / 100)%10)),      \
  ('0' + (((n) / 10)%10)),       \
  ('0' +  ((n) % 10))


char const info_version[] = { 'I', 'N', 'F', 'O', ':', 'v', 'e', 'r', 's', 'i', 'o', 'n', '[',
  DEC(CONFIG_XENO_VERSION_MAJOR), '.', DEC(CONFIG_XENO_VERSION_MINOR), '.', DEC(CONFIG_XENO_REVISION_LEVEL), ']', '\0' };

#ifdef CONFIG_XENO_UAPI_LEVEL
char const info_uapi_level[] = { 'I', 'N', 'F', 'O', ':', 'u', 'a', 'p', 'i', '_', 'l', 'e', 'v', 'e', 'l', '[',
  DEC(CONFIG_XENO_UAPI_LEVEL), ']', '\0' };
#endif
#ifdef CONFIG_XENO_VERSION_NAME
char const* info_version_name = "INFO" ":" "version_name[" CONFIG_XENO_VERSION_NAME "]";
#endif


int main(int argc, char * const *argv)
{
  xenomai_init(&argc, &argv);
  int res = 0;
  char *ptr = argv[0];
  res += ptr - info_version;
#ifdef CONFIG_XENO_UAPI_LEVEL
  res += ptr - info_uapi_level;
#endif
#ifdef CONFIG_XENO_VERSION_NAME
  res += ptr - info_version_name;
#endif
  return 0;
}
