c6c.o: c6.l c6.y c6c.c
	bison -y -d c6.y
	flex c6.l
	gcc -o $@ y.tab.c lex.yy.c c6c.c

nas.o:
	bison -d nas/nas.y
	flex nas/nas.l
	gcc -o $@ lex.yy.c nas.tab.c

nas2.o:
	bison -d nas2/nas2.y
	flex nas2/nas2.l
	gcc -o $@ lex.yy.c nas2.tab.c
