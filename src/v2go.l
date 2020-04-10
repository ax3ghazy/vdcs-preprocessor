%{
#include <stdio.h>
#include "y.tab.h"
/* #define DEBUG */
%}

%%

^\%  {
		#ifdef DEBUG
		printf("start ");
		#endif
		return START;
		}

if {
		#ifdef DEBUG
		printf("if ");
		#endif
		return IF;
		}

print {
		#ifdef DEBUG
		printf("print ");
		#endif
		return PRINT;
		}

["] {
		#ifdef DEBUG
		printf("quote ");
		#endif
		return QUOTE;
		}

= {
		#ifdef DEBUG
		printf("equal ");
		#endif
		return EQUAL;
		}

[(] {
		#ifdef DEBUG
		printf("( ");
		#endif
		return START_PARENTHESIS;
		}

[)] {
		#ifdef DEBUG
		printf(") ");
		#endif
		return END_PARENTHESIS;
		}

[a-zA-z]+[a-zA-Z0-9]* {
		#ifdef DEBUG
			printf("identifier ");
		#endif
		return IDENTIFIER;
		}

[\n] {
		#ifdef DEBUG
		printf("eol\n");
		#endif
		return EOL;
		}

[\t] {
		#ifdef DEBUG
		printf("indentation ");
		#endif
		return INDENT;
		}

[ ]			;

. {
		#ifdef DEBUG
		printf("other ");
		#endif
		return OTHER;
		}

%%
