YFLAGS	= -d
SRCDIR = ./src
YAC = yacc
LEX = flex
PROGRAM = v2go
OBJS = y.tab.o lex.yy.o
SRCS = y.tab.c lex.yy.c
CC = gcc

all: $(PROGRAM)

$(OBJS): $(SRCS)
	$(CC) -c $*.c -o $@ -O

y.tab.c: $(SRCDIR)/v2go.y
	$(YACC) $(YFLAGS) $(SRCDIR)/v2go.y

lex.yy.c: $(SRCDIR)/v2go.l
	$(LEX) $(SRCDIR)/v2go.l

v2go: $(OBJS)
	$(CC) $(OBJS) -o $@ -lfl -lm

clean:
	rm ‑f $(OBJS) v2go y.tab.* lex.yy.*
