%{
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#define BUFFER_SIZE 2048
#define MAX_PROGRAM_SIZE 50
extern char* yytext;
enum statement_t {ASSIGNMENT_ST, PRINT_ST};
enum expression_t {VAR_T, VDCS_T, GO_VALID_T};
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
char func_name[BUFFER_SIZE], operand1[BUFFER_SIZE], operand2[BUFFER_SIZE], expr[BUFFER_SIZE];

int assigned_vars_i = 0;
char assigned_vars[MAX_PROGRAM_SIZE][BUFFER_SIZE];
%}

%start list

%token <str> START INDENT QUOTE IDENTIFIER
%right <str> EQUAL PRINT IF
%right <str> START_PARENTHESIS
%left <str> END_PARENTHESIS
%token <str> OTHER SPACE EOL

%union {
  char *str;
}

%type <str> identifier expression statement other

%%

list: //empty
      | list EOL list
      | START statement
      | START indentation statement
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
	  |IF expression
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

indentation:
	     INDENT indentation
	     |INDENT
	     ;

other:
     	other other {strcat($$, $2);}
	| OTHER | IDENTIFIER | EQUAL | IF | PRINT | START | INDENT | QUOTE
	;

%%


int add_com(FILE* fptr, int i, const char * circ) {

  // number of servers
  fprintf(fptr, \
  "\t_%sCh%d := make(chan vdcs.ChannelContainer)\n \
  \tgo vdcs.Comm(\"%s\", %d, 6, 1, _%sCh%d)\n" \
		, circ, i, circ, i, circ, i);
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

int main(int argc, char *argv[]) {
// parse the input
 if (argc < 2) {
  printf("Usage: v2go <output_file>");
  exit(EXIT_FAILURE);
 }

 if (!yyparse()) {
  printf("INFO: Parsed successfully!\n");
 }

 int program_size = idx;
 int channel_idx = 0;
 char * line = NULL;
 size_t len = 0;
 ssize_t read;
 // args
 FILE *stub_vdcs_file = fopen("./src/stub.vdcs.go", "r");
 FILE *output_vdcs_file = fopen(argv[1], "w");


  if(stub_vdcs_file == NULL || output_vdcs_file == NULL) {
      printf("Error opening the files.\n");
      exit(EXIT_FAILURE);
  }


  // read stub and place the communication & threading routines:
  while ((read = getline(&line, &len, stub_vdcs_file)) != -1) {
    fprintf(output_vdcs_file, "%s", line);
  }

  fprintf(output_vdcs_file, "\n\t//VDCS Communications:\n");
  for (int i = 0; i < program_size; i++) {
   if (program[i].statement_type == ASSIGNMENT_ST) {
       if (program[i].expression_type == VDCS_T) {
         add_com(output_vdcs_file, channel_idx, program[i].VDCS_func_name);
         channel_idx++;
       }
   }
  }

////////////////
  fprintf(output_vdcs_file, "\n\t//USER PROGRAM:\n");
  channel_idx = 0;
  for (int i = 0; i < program_size; i++) {
    switch (program[i].statement_type) {
      case ASSIGNMENT_ST:
	if (program[i].expression_type == VDCS_T) {
	  char assig_char = is_assigned(program[i].VDCS_assignee)? ' ' : ':';
	  fprintf(output_vdcs_file, "\t%s %c= eval(%s, %s, %d, _%sCh%d)\n", \
	  program[i].VDCS_assignee, assig_char, program[i].VDCS_operand1,  program[i].VDCS_operand2, \
	  channel_idx, program[i].VDCS_func_name, channel_idx);
	  channel_idx++;
	} else {
	  char assig_char = is_assigned(program[i].VDCS_assignee)? ' ' : ':';
	  fprintf(output_vdcs_file, "\t%s %c= %s\n", \
	  program[i].VDCS_assignee, assig_char, program[i].VDCS_expr);

	}
	add_to_assigned_vars(program[i].VDCS_assignee);
	break;
      case PRINT_ST:
	if (program[i].expression_type == VDCS_T) {

	  /* channel_idx++; */
	} else {
	  fprintf(output_vdcs_file, "\tfmt.Println(%s)\n", program[i].VDCS_expr);
	}
	break;
      break;

   }
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

void yyerror(s)
char *s;
{
  fprintf(stderr, "%s\n",s);
}

int yywrap()
{
  return(1);
}
