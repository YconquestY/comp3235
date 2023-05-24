array a[2] = 1,
      b[2] = 2,
      c[2] = 3;
d = 4;
foo(a, b, c);
boo(b, c, d);
func foo(a, b, c) {
    if (c[0] != 0) { 
        c[1] = a[1];
    }
    else {
        c[1] = b[1];
    }
}
func boo(b, c, d) {
    for (i = 0; i < d; i = i + 1;) {
        c[0] = c[0] + b[0] + i;
    }
    e = 1;
    f = 2;
    g = 3;
}
puts_("array c:");
for (i = 0; i < 2; i = i + 1;) {
    putc_(' ');
    puti_(c[i]);
}
puts("end");