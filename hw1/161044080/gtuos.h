#ifndef H_GTUOS
#define H_GTUOS

#include "8080emuCPP.h"
#include <fstream>

using namespace std;

class GTUOS {
public:
    uint64_t handleCall(const CPU8080 & cpu);
    GTUOS();
    ~GTUOS();

private:
    enum  Types {
        PRINT_B = 1,
        PRINT_MEM = 2,
        READ_B = 3,
        READ_MEM = 4,
        PRINT_STR = 5,
        READ_STR = 6
    };
    
    ofstream out;
    ifstream in;
    uint16_t hp;
};

#endif

