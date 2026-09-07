/* iPhoneOS9.3 TBD + Linux clang often fails to bind memset for armv7 device links.
 * Providing a local definition avoids -undefined dynamic_lookup (which crashes on device). */
void *memset(void *s, int c, unsigned long n) {
	unsigned char *p = (unsigned char *)s;
	while (n--) {
		*p++ = (unsigned char)c;
	}
	return s;
}
