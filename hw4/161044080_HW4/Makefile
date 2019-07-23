exe:gtuos.o 8080emu.o main.o memory.o
	g++ -std=c++11 gtuos.o 8080emu.o main.o memory.o -o exe

gtuos.o:gtuos.cpp
	g++ -std=c++11 -c gtuos.cpp

8080emu.o:8080emu.cpp
	g++ -std=c++11 -c 8080emu.cpp

main.o:main.cpp
	g++ -std=c++11 -c main.cpp

memory.o:memory.cpp
	g++ -std=c++11 -c memory.cpp

run:
	./exe MicroKernel.com 0

clean:
	rm *.o exe
