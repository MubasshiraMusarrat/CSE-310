flex 1905088_lex.l
echo "lex.yy.c created."
bison -d -t 1905088_parser.y
echo "parser.tab.h and parser.tab.c created."
g++ lex.yy.c 1905088_parser.tab.c -lfl -w -o parser.out
echo "compilation completed. parser.out is ready to execute."
echo "parser.out executed."
./parser.out test5_i.c