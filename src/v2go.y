%{
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#define BUFFER_SIZE 2048
#define MAX_PROGRAM_SIZE 1024
extern char* yytext;

FILE *output_vdcs_file;
int number_servers = 4;

enum statement_t {ASSIGNMENT_ST, PRINT_ST, IF_ST, END_BRACE_ST, ELSE_ST, REPEAT_ST};
enum expression_t {VAR_T, VDCS_T, NUMBER_T, GO_VALID_T};
struct program_statment_t {
  enum statement_t statement_type;
  enum expression_t expression_type;
  char VDCS_assignee[BUFFER_SIZE];
  char VDCS_func_name[BUFFER_SIZE];
  char VDCS_operand1[BUFFER_SIZE];
  char VDCS_operand2[BUFFER_SIZE];
  char VDCS_expr[BUFFER_SIZE];
};

enum expression_t expr_type;
struct program_statment_t program[MAX_PROGRAM_SIZE];
int idx = 0;
int channel_idx = 0;
char func_name[BUFFER_SIZE], operand1[BUFFER_SIZE], operand2[BUFFER_SIZE], expr[BUFFER_SIZE];

int assigned_vars_i = 0;
char assigned_vars[MAX_PROGRAM_SIZE][BUFFER_SIZE];


// brace stack
int braces_open = 0;
int repeat_number = 0;
int repeat_level = 0;
int repeat_i = -1;
%}

%start list

%token <str> START QUOTE IDENTIFIER DIGIT
%right <str> EQUAL PRINT IF ELSE REPEAT
%right <str> START_PARENTHESIS START_BRACE
%left <str> END_PARENTHESIS END_BRACE
%token <str> OTHER SPACE EOL

%union {
  char *str;
}

%type <str> identifier expression statement other number

%%

list: //empty
      | list EOL list
      | START statement
      ;

statement:
	   identifier EQUAL expression {
	    program[idx].statement_type = ASSIGNMENT_ST;
	    program[idx].expression_type = expr_type;
	    strcpy(program[idx].VDCS_assignee, $1);
	    strcpy(program[idx].VDCS_func_name, func_name);
	    strcpy(program[idx].VDCS_operand1, operand1);
	    strcpy(program[idx].VDCS_operand2, operand2);
	    strcpy(program[idx].VDCS_expr, expr);
	    idx++;
	  }
	  |REPEAT number START_BRACE {
	    braces_open++;
	    program[idx].statement_type = REPEAT_ST;
	    program[idx].expression_type = NUMBER_T;
	    printf("number=%s\n", $2);
	    strcpy(program[idx].VDCS_expr, $2);
	    idx++;
	  }
	  |IF expression START_BRACE {
	    braces_open++;
	    program[idx].statement_type = IF_ST;
	    program[idx].expression_type = expr_type;
	    strcpy(program[idx].VDCS_expr, expr);
	    idx++;
	  }
	  | END_BRACE {
	    if (braces_open > 0) {
	      braces_open--;
	      /* printf("braces_openUP: %d", braces_open); */
	      program[idx].statement_type = END_BRACE_ST;
	      idx++;
	    } else {
	      printf("Error: unmatched braces");
	      exit(EXIT_FAILURE);
	    }
	  }
	  |END_BRACE ELSE START_BRACE {
	    if (braces_open > 0) {
	      /* printf("else_expr"); */
	      /* printf("braces_openDOWN%d", braces_open); */
	      program[idx].statement_type = ELSE_ST;
	      idx++;
	    } else {
	      printf("Error: unmatched braces");
	      exit(EXIT_FAILURE);
	    }
	  }
	  |PRINT expression {
	    program[idx].statement_type = PRINT_ST;
	    program[idx].expression_type = expr_type;
	    strcpy(program[idx].VDCS_expr, expr);
	    idx++;
	  }
	  ;

expression:
	  	identifier {
		  expr_type = VAR_T;
		  strcpy(expr, $1);
		}
	  	|identifier identifier identifier {
		  expr_type = VDCS_T;
		  strcpy(func_name, $1);
		  strcpy(operand1, $2);
		  strcpy(operand2, $3);
		} //myEqual a b
		|START_PARENTHESIS other END_PARENTHESIS {
		/* printf("_>%s", $2); */
		  expr_type = GO_VALID_T;
		  strcpy(expr, $2);
		}
		;

identifier:
	  IDENTIFIER {$$ = $1;}
	;

number:
     	number number {strcat($$, $2);}
	| DIGIT
	;

other:
     	other other {strcat($$, $2);}
	| OTHER | IDENTIFIER | EQUAL | IF | ELSE | REPEAT | PRINT | START | QUOTE | DIGIT
	;

%%


int add_com(FILE* fptr, int i, const char * circ) {

  fprintf(fptr, \
  "\t_%sCh%d := make(chan vdcs.ChannelContainer)\n \
  \tgo vdcs.Comm(\"%s\", %d, %d, 1, _%sCh%d)\n" \
		, circ, i, circ, i, number_servers, circ, i);
}

int is_assigned (const char * var) {
  for (int i = 0; i < assigned_vars_i; i++) {
    if (strcmp(var, assigned_vars[i]) == 0) {
      return 1;
    }
  }
  return 0;
}

void add_to_assigned_vars(const char * var) {
  if (is_assigned(var)) {
      return;
  }
  strcpy(assigned_vars[assigned_vars_i], var);
  assigned_vars_i++;
}

void process_line(int i, int com_mode) {

    switch (program[i].statement_type) {
      case REPEAT_ST: // cannot be nested for now
	/* printf("REPEAT:braces at level: %d", braces_open); */
	braces_open++;
	repeat_number = atoi(program[i].VDCS_expr);
	repeat_level = braces_open;
	repeat_i = i;
	break;
      case ASSIGNMENT_ST:
	if (program[i].expression_type == VDCS_T) {
	  if (com_mode && !repeat_level) {
	    add_com(output_vdcs_file, channel_idx, program[i].VDCS_func_name);
	    channel_idx++;
	  } else {
	    char assig_char = is_assigned(program[i].VDCS_assignee)? ' ' : ':';
	    if (!repeat_level) {
	      fprintf(output_vdcs_file, "\t%s %c= eval(%s, %s, %d, _%sCh%d)\n", \
	      program[i].VDCS_assignee, assig_char, program[i].VDCS_operand1,  program[i].VDCS_operand2, \
	      channel_idx, program[i].VDCS_func_name, channel_idx);
	      add_to_assigned_vars(program[i].VDCS_assignee);
	      channel_idx++;
	    }
	  }
	} else if (!com_mode) {
	  char assig_char = is_assigned(program[i].VDCS_assignee)? ' ' : ':';
	  if (!repeat_level) {
	    fprintf(output_vdcs_file, "\t%s %c= %s\n", \
	    program[i].VDCS_assignee, assig_char, program[i].VDCS_expr);

	    add_to_assigned_vars(program[i].VDCS_assignee);
	  }
	}
	break;
      case PRINT_ST:
	if (program[i].expression_type == VDCS_T) {

	  /* channel_idx++; */
	} else if (!com_mode){
	  if (!repeat_level)
		fprintf(output_vdcs_file, "\tfmt.Println(%s)\n", program[i].VDCS_expr);
	}
	break;
      case IF_ST:
	/* printf("IF:braces at level: %d", braces_open); */
	braces_open++;
	if (program[i].expression_type == VDCS_T) {
	  if (com_mode) {
	    add_com(output_vdcs_file, channel_idx, program[i].VDCS_func_name);
	  } else {
	    if (!repeat_level)
	      fprintf(output_vdcs_file, "\tif eval(%s, %s, %d, _%sCh%d) { \n", \
	    program[i].VDCS_operand1,  program[i].VDCS_operand2, \
	    channel_idx, program[i].VDCS_func_name, channel_idx);
	  }
	  printf("\nnew channel if\n");
	  channel_idx++;
	} else if (!com_mode) {
	  if (!repeat_level)
	    fprintf(output_vdcs_file, "\tif %s {\n", program[i].VDCS_expr);
	}
	break;
      case ELSE_ST:
	  if (!com_mode) {
	    if (!repeat_level) {
	      fprintf(output_vdcs_file, "\t} else {\n");
	    }
	  }
	break;
      case END_BRACE_ST:
	    braces_open--;
	    /* printf("line:%d\n", i); */
	    /* printf("END:braces at level: %d\n", braces_open); */
	    if (repeat_level == braces_open+1) {
	      repeat_level = 0;
	      for (int k = 0; k < repeat_number; k++) {
	        for (int j = repeat_i+1; j < i; j++) {
	          process_line(j, com_mode);
	        }
	      }
	      repeat_number = 0;
	      repeat_i = -1;
	    } else if (!com_mode) {
		if (!repeat_level)
		  fprintf(output_vdcs_file, "\t}\n");
	    }

	break;

   }

}

int main(int argc, char *argv[]) {
// parse the input
 if (argc < 2) {
  printf("Usage: v2go <output_file>");
  exit(EXIT_FAILURE);
 }

 if (!yyparse()) {
  printf("INFO: Parsed successfully!\n");
 }

 if (braces_open) {
  printf("ERROR: Unmatched braces after parsing\n");
  exit(EXIT_FAILURE);
 }

 int program_size = idx;
 channel_idx = 0;
 char * line = NULL;
 size_t len = 0;
 ssize_t read;
 // args
 FILE *stub_vdcs_file = fopen("./src/stub.vdcs.go", "r");
 output_vdcs_file = fopen(argv[1], "w");


  if(stub_vdcs_file == NULL || output_vdcs_file == NULL) {
      printf("Error opening the files.\n");
      exit(EXIT_FAILURE);
  }


  // read stub and place the communication & threading routines:
  while ((read = getline(&line, &len, stub_vdcs_file)) != -1) {
    fprintf(output_vdcs_file, "%s", line);
  }

  // comm insertion
  fprintf(output_vdcs_file, "\n\t//VDCS Communications:\n");
  for (int i = 0; i < program_size; i++) {
    process_line(i, 1); //com mode
  }

////////////////
  fprintf(output_vdcs_file, "\n\t//USER PROGRAM:\n");
  channel_idx = 0;
  for (int i = 0; i < program_size; i++) {
    process_line(i, 0);
  }

  fprintf(output_vdcs_file, "\n}\n"); // end main


  // eval function
  // only a single eval works for now

/*
 channel_idx = 0;
  for (int i = 0; i < program_size; i++) {
   if (program[i].statement_type == ASSIGNMENT_ST) {
       if (program[i].expression_type == VDCS_T) {
         add_eval...
         channel_idx++;
       }
   }
  }
*/
 fprintf(output_vdcs_file, \
"func eval (a string, b string, cID int64, chVDCSEvalCircRes <-chan vdcs.ChannelContainer) (bool){\n\
   _inWire0:=[]byte(a)\n\
   _inWire1:=[]byte(b)\n\
   //generate input wires for given inputs\n\
   k := <-chVDCSEvalCircRes\n \
   myInWires := make([]vdcs.Wire, len(_inWire0)*8*2)\n \
   for idxByte := 0; idxByte < len(_inWire0); idxByte++ {\n \
     for idxBit := 0; idxBit < 8; idxBit++ {\n \
       contA := (_inWire0[idxByte] >> idxBit) & 1\n \
       myInWires[(idxBit+idxByte*8)*2] = k.InputWires[(idxBit+idxByte*8)*4+int(contA)]\n \
       contB := (_inWire1[idxByte] >> idxBit) & 1\n \
       myInWires[(idxBit+idxByte*8)*2+1] = k.InputWires[(idxBit+idxByte*8)*4+2+int(contB)]\n \
     }\n \
   }\n \
   message := vdcs.Message{\n \
     Type:       []byte(\"CEval\"),\n \
     ComID:      vdcs.ComID{CID: []byte(strconv.FormatInt(cID, 10))},\n \
     InputWires: myInWires,\n \
     NextServer: vdcs.MyOwnInfo.PartyInfo,\n \
   }\n \
   key := vdcs.RandomSymmKeyGen()\n \
   messageEnc := vdcs.EncryptMessageAES(key, message)\n \
   nkey, err := vdcs.RSAPublicEncrypt(vdcs.RSAPublicKeyFromBytes(k.PublicKey), key)\n \
   if err != nil {\n \
     panic(\"Invalid PublicKey\")\n \
   }\n \
   mTmp := make([]vdcs.Message, 1)\n \
   mTmp[0] = messageEnc\n \
   kTmp := make([][]byte, 1)\n \
   kTmp[0] = nkey\n \
   msgArr := vdcs.MessageArray{\n \
     Array: mTmp,\n \
     Keys:  kTmp,\n \
   }\n \
   for ok := vdcs.SendToServer(msgArr, k.IP, k.Port); !ok; {\n \
   }\n \
   var res vdcs.ResEval\n \
   for true {\n \
     vdcs.ReadyMutex.RLock()\n \
     tmpflag := vdcs.ReadyFlag\n \
     vdcs.ReadyMutex.RUnlock()\n \
     if tmpflag == true {\n \
       break\n \
     }\n \
     time.Sleep(1 * time.Second)\n \
   }\n \
   vdcs.ReadyMutex.RLock()\n \
   res = vdcs.MyResult\n \
   vdcs.ReadyMutex.RUnlock()\n \
   vdcs.ReadyMutex.Lock()\n \
   vdcs.ReadyFlag = false\n \
   vdcs.ReadyMutex.Unlock()\n \
   //validate and decode res\n \
   if bytes.Compare(res.Res[0], k.OutputWires[0].WireLabel) == 0 {\n \
     return false\n \
   } else if bytes.Compare(res.Res[0], k.OutputWires[1].WireLabel) == 0 {\n \
     return true\n \
   } else {\n \
     panic(\"The server cheated me while evaluating\")\n \
   }\n \
}");

 printf("INFO: Output written to %s\n", argv[1]);

 fclose(stub_vdcs_file);
 fclose(output_vdcs_file);
 if (line) free(line);

 return 0;
}

void
yyerror (char const *s)
{
  fprintf (stderr, "%s\n", s);
}

int yywrap()
{
  return(1);
}
