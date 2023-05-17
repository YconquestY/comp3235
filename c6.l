%{
#include <stdlib.h>
#include "calc3.h"
#include "y.tab.h"
void yyerror(char *);
%}

%%


0	{
                yylval.iValue = atol(yytext);
                return INTEGER;
	}

[1-9][0-9]* {
                yylval.iValue = atol(yytext);
                return INTEGER;
	}
'.'	{
		yylval.iValue = (long) yytext[1];
		return INTEGER;
	}

\".+\"	{
		yytext[yyleng-1]=0;
		yylval.iValue = (long) yytext+1;
		return STRING; }

[-()<>=+*/;{}.%] {
                return *yytext;
	}

">="            return GE;
"<="            return LE;
"=="            return EQ;
"!="            return NE;
"for"		return FOR;
"while"         return WHILE;
"if"            return IF;
"else"          return ELSE;
"print"         return PRINT;
"puti"          return PRINT;
"puti_"         return PUTI_;
"puts"          return PUTS;
"puts_"         return PUTS_;
"putc"          return PUTC;
"putc_"         return PUTC_;
"getc"		return GETC;
"geti"		return READ;
"gets"		return GETS;
"read"		return READ;
"&&"		return AND;
"||"		return OR;

[[:alpha:]][[:alnum:]]* {
	yylval.iValue = (long) yytext; return VARIABLE;
}

\/\/.*\n	;	/* skip comments */

[ \t\n]+        ;       /* ignore whitespace */

.               yyerror("Unknown character");
%%
int yywrap(void) {
    return 1;
}
