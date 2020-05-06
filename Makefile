YFLAGS	= -d
SRCDIR = ./src
YAC = bison -y
LEX = flex
PROGRAM = v2go
OBJS = y.tab.o lex.yy.o
SRCS = y.tab.c lex.yy.c
CC = gcc

all: $(PROGRAM)

$(OBJS): $(SRCS)
	$(CC) -g -c $*.c -o $@ -O

y.tab.c: $(SRCDIR)/v2go.y lex.yy.c
	$(YACC) $(YFLAGS) $(SRCDIR)/v2go.y

lex.yy.c: $(SRCDIR)/v2go.l
	$(LEX) $(SRCDIR)/v2go.l

v2go: $(OBJS)
	$(CC) -g $(OBJS) -o $@ -lfl -lm

clean:
	rm ‑f $(OBJS) v2go y.tab.* lex.yy.* output.vdcs.go

test: $(PROGRAM)
	./v2go ./client.go < test/test_repeat.in
	gofmt -w ./client.go
