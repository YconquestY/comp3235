array a[3] = 1,
      b[3] = 2;

foo(a);
boo(b);

puts_("array a:");
for (i = 0; i < 3; i = i + 1;) {
    putc_(' ');
    puti_(a[i]);
}
puts(" end");

puts_("array b:");
for (i = 0; i < 3; i = i + 1;) {
    putc_(' ');
    puti_(b[i]);
}
puts(" end");

func foo(a) {
    moo(a);
}
func boo(b) {
    moo(@b);
}
func moo(arr) {
    arr[0] = -arr[0];
}