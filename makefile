c6c.o: lex.yy.c y.tab.c c6c.c
	gcc -o $@ y.tab.c lex.yy.c c6c.c

lex.yy.c: c6.l
	flex c6.l

y.tab.c: c6.y
	bison -y -d c6.y

nas.o:
	flex nas/nas.l
	bison -d nas/nas.y
	gcc -o $@ lex.yy.c nas.tab.c

nas2.o:
	flex nas2/nas2.l
	bison -d nas2/nas2.y
	gcc -o $@ lex.yy.c nas2.tab.c
