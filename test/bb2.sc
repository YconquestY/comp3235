array a[5] = 1;
func scan(a, size) {
    for (i = 1; i < size; i = i + 1;) {
        a[i] = a[i] + a[i-1];
    }
}
scan(a, 5);
puts_("a[5]:");
for (i = 0; i < 5; i = i + 1;) {
    putc_(' ');
    puti_(a[i]);
}
puts(" end");