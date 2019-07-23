#ifndef H_GTUOS
#define H_GTUOS

#include "8080emuCPP.h"
#include <fstream>
#include <vector>

using namespace std;

class GTUOS {
public:
    uint64_t handleCall(CPU8080 & cpu);
    void printContextSwitch(CPU8080& cpu);
    GTUOS();
    ~GTUOS();

private:
    enum  Types {
        PRINT_B = 1,
        PRINT_MEM = 2,
        READ_B = 3,
        READ_MEM = 4,
        PRINT_STR = 5,
        READ_STR = 6,
        LOAD_EXEC =7,
        PROCESS_EXIT =8,
        SET_QUANTUM =9,
        RAND_INT =10,
        WAIT =11,
        SIGNAL =12 
    };
    uint16_t hp;
    ofstream out;
    ifstream in;
    ofstream localList, mailBox;
};

#endif