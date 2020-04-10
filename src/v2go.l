%{
#include <stdio.h>
#include "y.tab.h"
%}

%%

^\% 			{printf("start "); return START;}
if			{printf("if "); return IF;}
print			{printf("print "); return PRINT;}
["]			{printf("quote "); return QUOTE;}
=			{printf("equal "); return EQUAL;}
[(]			{printf("( "); return START_PARENTHESIS;}
[)]			{printf(") "); return END_PARENTHESIS;}
[a-zA-z]+[a-zA-Z0-9]*	{printf("identifier "); return IDENTIFIER;}
[\n]			{printf("eol\n"); return EOL;}
[\t]			{printf("indentation "); return INDENT;}
[ ]			;
.			{printf("other "); return OTHER;}

%%
