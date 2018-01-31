all: clean game

game: game.c game.o
	gcc -std=c99 -g -o game game.c game.o

%.o: %.s
	as -o $@ -g $<

%: %.o
	ld $< -o $@ -lc

clean:
	rm -vf game *.o

