%{
#include <stdio.h>
#define YYSTYPE char*
extern char* yytext;
%}

%start list

%token START INDENT QUOTE IDENTIFIER
%right EQUAL PRINT IF
%right START_PARENTHESIS
%left END_PARENTHESIS
%token OTHER EOL

%%

list: //empty
      | list EOL list
      | START statement
      | START indentation statement
      ;

statement:
	   identifier EQUAL expression
          |identifier EQUAL START_PARENTHESIS other END_PARENTHESIS
	  |IF expression
	  |PRINT expression
	  ;

expression:
	  	QUOTE other QUOTE    // "test"
	  	|identifier
	  	|identifier identifier identifier //myEqual a b
		;

identifier:
	  IDENTIFIER {$$ = strdup(yytext);}
	;

indentation:
	     INDENT indentation
	     |INDENT
	     ;

other:
     	other other
	| OTHER | IDENTIFIER | EQUAL | IF | PRINT | START | INDENT
	;

%%
main()
{
 return(yyparse());
}

yyerror(s)
char *s;
{
  fprintf(stderr, "%s\n",s);
}

yywrap()
{
  return(1);
}
