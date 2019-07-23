#include <iostream>
#include "memory.h"
#include <iomanip>

using namespace std;

Memory::Memory(uint64_t size, ofstream& fault) : pageFault(fault) {
    mem = (uint8_t*) calloc(size, sizeof (uint8_t));
    ram = (uint8_t*) calloc(8192, sizeof (uint8_t));
    pageTable.open("pagetable.txt", ios::out | ios::trunc);
    baseRegister = 0;
    limitRegister = 0;
}

Memory::~Memory() {
    free(mem);
    pageTable.close();
}

uint8_t& Memory::physicalAt(uint32_t ind) {
    return mem[ind];
}

uint16_t Memory::getBaseRegister() const {
    return baseRegister;
}

uint16_t Memory::getLimitRegister() const {
    return limitRegister;
}

void Memory::setBaseRegister(uint16_t base) {
    this->baseRegister = base;
}

void Memory::setLimitRegister(uint16_t limit) {
    this->limitRegister = limit;
}

uint8_t& Memory::at(uint32_t ind) {
    int offset = 0x3ff & ind;
    int index = (ind & 0x3fff) >> 10;
    int address;
    int id, base;

    id = ind / 16384;
    base = id * 16384;
    index = (ind - base) / 1024;

    if (256 <= ind && ind <= 269) {
        return physicalAt(ind);
    }

    if (virtualTable[id].present[index]) {
        address = (virtualTable[id].table[index] << 10) | offset;
        virtualTable[id].modified[index] = 1;
        return ram[address];
    } else { // page fault
        address = index << 10;
        address += base;
        int memIndex = pageReplacement(address);
        virtualTable[id].table[index] = memIndex;
        memTable.ramIndex[memIndex] = index;
        memTable.ramId[memIndex] = id;
        virtualTable[id].present[index] = true;
        virtualTable[id].referenced[index] = 1;
        printPageTable();
        pageFault << "PAGEFAULT: Current_PID: " << id << " Virtual_Address: " << memIndex
                << " Physical_Address: " << address << " Page_To_Be_Replaced: " << (index >> 10) << endl;
        return at(ind);
    }
}

int Memory::pageReplacement(int address) {
    int index = fifoIndex;
    if (memTable.ramRef[index]) {

        int memId = memTable.ramId[index];
        int memIndex = memTable.ramIndex[index];
        int base = memId * 16384;
        virtualTable[memId].present[memIndex] = false;
        virtualTable[memId].modified[memIndex] = 0;
        virtualTable[memId].referenced[memIndex] = 0;
        virtualTable[memId].table[memIndex] = 0;
        int oldAddress = (memIndex << 10) + base;
        int ramAddress = index << 10;
        for (int i = oldAddress, j = ramAddress; i < oldAddress + 1024; ++i, ++j) {
            mem[i] = ram[j];
        }
    }
    memTable.ramRef[index] = true;
    index = index << 10;
    for (int i = address, j = 0; i < address + 1024; ++i, ++j) {
        ram[index + j] = physicalAt(i);
    }

    ++fifoIndex;
    if (7 < fifoIndex) {
        fifoIndex = 0;
    }

    return ( index >> 10);
}

string Memory::getName(int id) {
    switch (id) {

        case 0:
        {
            return "OS";
        }
        case 1:
        {

            return "Sum";
        }
        case 2:
        {
            return "Primes";
        }
        case 3:
        {

            return "Sort";
        }
    }
    return "";
}

void Memory::printPageTable() {

    pageTable << "Page Fault Happened:" << endl;
    for (int i = 0; i < 4; ++i) {
        pageTable << "Table-" << getName(i) << endl;
        pageTable << "| index  | address | present | referenced | modified |" << endl;
        for (int j = 0; j < 16; ++j) {
            pageTable << "|   " << setw(2) << j << "   |   " << (virtualTable[i].present[j] ? virtualTable[i].table[j] + 1 : virtualTable[i].table[j])
                    << "     |   " << virtualTable[i].present[j] << "     |     "
                    << virtualTable[i].referenced[j] << "      |     " << virtualTable[i].modified[j] << "    |" << endl;

        }
        for (int j = 0; j < 55; ++j)
            pageTable << "-";

        pageTable << endl << endl;

    }
}