#ifndef H_MEMORY
#define H_MEMORY

#include <cstdlib>
#include "memoryBase.h"
#include <iostream>
#include <fstream>

using namespace std;


class Memory : public MemoryBase {
public:
    Memory(uint64_t size,ofstream& fault);
    ~Memory();
    virtual uint8_t & at(uint32_t ind);
    void printPageTable();
    virtual uint8_t & physicalAt(uint32_t ind);
    int pageReplacement(int addres);
    uint16_t getBaseRegister() const;
    uint16_t getLimitRegister() const;
    void setBaseRegister(uint16_t base);
    void setLimitRegister(uint16_t limit);
    string getName(int id);

private:
    uint8_t * mem;
    uint16_t baseRegister;
    uint16_t limitRegister;
    ofstream& pageFault;
    ofstream pageTable;
    uint8_t *ram;
    int fifoIndex =0;

    struct Table {
        int table[16]={0};
        int referenced[16]={0};
        int modified[16] ={0};
        bool present[16] ={false};
    };
    
    struct RamTable{
        bool ramRef[8]={false};
        int ramId[8]={0};
        int ramIndex[8]={0};
    };

    Table virtualTable[16];
    RamTable memTable;
};

#endif

