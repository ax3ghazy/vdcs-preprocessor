%{
#include <stdio.h>
#include "y.tab.h"
#define DEBUG
%}

%%

^\%  {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("start ");
		#endif
		return START;
		}

if {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("if ");
		#endif
		return IF;
		}

else {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("else ");
		#endif
		return ELSE;
		}

repeat {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("repeat ");
		#endif
		return REPEAT;
		}

print {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("print ");
		#endif
		return PRINT;
		}

["] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("quote ");
		#endif
		return QUOTE;
		}

= {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("equal ");
		#endif
		return EQUAL;
		}

[(] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("( ");
		#endif
		return START_PARENTHESIS;
		}

[)] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf(") ");
		#endif
		return END_PARENTHESIS;
		}

[{] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("{ ");
		#endif
		return START_BRACE;
		}

[}] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("} ");
		#endif
		return END_BRACE;
		}

[0-9]+ {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("digit ");
		#endif
		return DIGIT;
		}

[a-zA-z_]+[a-zA-Z0-9_]* {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
			printf("identifier ");
		#endif
		return IDENTIFIER;
		}

[\n] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("eol\n");
		#endif
		return EOL;
		}


[ \t] {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("space ");
		#endif
		/* return SPACE; */
		}


. {
		yylval.str = strdup(yytext);
		#ifdef DEBUG
		printf("other ");
		#endif
		return OTHER;
		}

%%
