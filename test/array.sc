array a[2] = 1,
      b[2,2] = 2,
      c[3,3,3] = 3,
      d[4,4] = 0;
puts_("d[1,3] = 2 + 3 + your number, which is: "); geti(input);
d[ a[1], c[ a[0], 0 + b[a[1], 0], b[1,0] ] ] = b[0,1] + c[b[1,1], 2, 0] + input; // d[1,3] = 2 + 3;
for (i = 0; i < 4; i = i + 1;) {
  for (j = 0; j < 4; j = j + 1;) {
    if (j < 3) {
      puti_(d[i,j]);
      putc_(' ');
    }
    else {
      puti(d[i,j]);
    }
  }
}