#include <iostream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include "memory.h"
#include <time.h>
#include <string>

using namespace std;

GTUOS::GTUOS() : hp(0x0F00) {
    out.open("output.txt",ios::out);
    in.open("input.txt");
    localList.open("locallist.txt", ios::out);
    mailBox.open("mailbox.txt", ios::out);
    srand(time(NULL));
}

GTUOS::~GTUOS() {
    in.close();
    out.close();
    localList.close();
    mailBox.close();
}

void GTUOS::printContextSwitch(CPU8080& cpu) {
    if (*cpu.lastOpcode == 0xe9) {
        int address = 0x2000;
        mailBox <<"Context switch happened :\n";
        for (int i = 0; i<static_cast<int> (cpu.memory->physicalAt(address + 2)); ++i) {
            mailBox << static_cast<int> (cpu.memory->physicalAt(address + 3 + i)) << " ";
        }
        mailBox << "\n";

        address =(cpu.memory->physicalAt(2054)<<8) | cpu.memory->physicalAt(2053); 
        int size =address-12288;
        localList<<"Context switch happened :\n";
        for (int i = 0; i<size; ++i) {
            localList << static_cast<int> (cpu.memory->physicalAt(12288 + i)) << " ";
        }
        localList << "\n";
    }
}

uint64_t GTUOS::handleCall(CPU8080 & cpu) {
    unsigned char type = cpu.state->a;
    cpu.state->pc++;
    int n =rand()%10;
    switch (type) {
        case PRINT_B:
        {
            out << (int) cpu.state->b;
            break;
        }
        case PRINT_MEM:
        {
            uint32_t offset = (cpu.state->b << 8) | cpu.state->c;
            out << (int) cpu.memory->at(offset) << endl;
            break;
        }
        case READ_B:
        {
            int t = 0;
            in>>t;
            cpu.state->b = t;
            break;
        }
        case READ_MEM:
        {
            int t = 0;
            in>>t;
            cpu.memory->at(hp) = t;
            cpu.state->b = (hp & 0xFF00) >> 8;
            cpu.state->c = (hp & 0x00FF);
            ++hp;
            break;
        }
        case PRINT_STR:
        {
            uint32_t offset = (cpu.state->b << 8) | cpu.state->c;
            string str;
            char t = cpu.memory->at(offset);
            while (t != '\0') {
                str += t;
                ++offset;
                t = cpu.memory->at(offset);
            }
            out << str;
            break;

        }
        case READ_STR:
        {
            cpu.state->b = (hp & 0xFF00) >> 8;
            cpu.state->c = (hp & 0x00FF);
            string str;
            getline(in, str);
            for (int i = 0; i < str.size(); ++i) {
                cpu.memory->at(hp) = str[i];
                ++hp;
            }
            cpu.memory->at(hp) = '\0';
            ++hp;
            break;
        }
        case LOAD_EXEC:
        {

            uint32_t offset = (cpu.state->b << 8) | cpu.state->c;
            string str;
            char t = cpu.memory->at(offset);
            while (t != '\0') {
                str += t;
                ++offset;
                t = cpu.memory->at(offset);
            }
            uint32_t startAddress = (cpu.state->h << 8) | cpu.state->l;
            cpu.ReadFileIntoMemoryAt(str.data(), startAddress);
            int stack = startAddress + 1024;

            uint16_t base = ((Memory*) (cpu.memory))->getBaseRegister();
            cpu.memory->physicalAt(stack - 1) = 0;
            cpu.memory->physicalAt(stack - 2) = 0;
            cpu.memory->physicalAt(stack - 3) = 0;
            cpu.memory->physicalAt(stack - 4) = 0;
            cpu.memory->physicalAt(stack - 5) = 0;
            cpu.memory->physicalAt(stack - 6) = 0;
            cpu.memory->physicalAt(stack - 7) = 0;
            cpu.memory->physicalAt(stack - 8) = (startAddress >> 8)&0xff; //pc high
            cpu.memory->physicalAt(stack - 9) = startAddress & 0xff; //pc low
            cpu.memory->physicalAt(stack - 10) = 0;
            cpu.memory->physicalAt(stack - 11) = 0;
            cpu.memory->physicalAt(stack - 12) = 0;
            cpu.memory->physicalAt(stack - 13) = *(unsigned char *) &cpu.state->cc;
            cpu.state->int_enable = 1;
            cpu.dispatchScheduler();
            break;
        }
        case PROCESS_EXIT:
        {
            ((Memory*) (cpu.memory))->setBaseRegister(0);
            cpu.state->pc = 43;

            break;
        }
        case SET_QUANTUM:
        {
            int t = cpu.state->b;
            cpu.setQuantum(t);
        }
        case RAND_INT:
        {
            cpu.state->b = rand() % 256;
            break;
        }
        case WAIT:
        {
            int address = 0x2000 + 53 * (cpu.state->b - 1); // go to mailbox address
            if (cpu.memory->physicalAt(address + 1) == 0 && cpu.memory->physicalAt(address + 2) == 0) {
                cpu.memory->physicalAt(address + 1) = 50;
            }
            int mutex = cpu.memory->physicalAt(address);
            if (cpu.state->c == 1 && cpu.memory->physicalAt(address + 1) > 0 && mutex == 0) { // sender 
                cpu.memory->physicalAt(address) = 1;
                cpu.memory->physicalAt(address + 1)--; // decrease empty semaphore
                cpu.state->c = cpu.memory->physicalAt(address + 2);
            } else if (cpu.state->c == 2 && cpu.memory->physicalAt(address + 2) > n && mutex == 0) { // receiver
                cpu.memory->physicalAt(address) = 1;
                cpu.memory->physicalAt(address + 2)--; // decrease full semaphore
                cpu.state->c = cpu.memory->physicalAt(address + 2);
            } else {
                cpu.state->pc--;
                cpu.scheduler_timer = 0;
                cpu.dispatchScheduler();
            }
            break;
        }
        case SIGNAL:
        {
            int address = 0x2000 + 53 * (cpu.state->b - 1);  // go to mailbox address
            int mutex = cpu.memory->physicalAt(address);
            if (cpu.state->c == 1 && mutex == 1) { // receiver 
                cpu.memory->physicalAt(address) = 0;
                cpu.memory->physicalAt(address + 1)++; // increase empty semaphore
                cpu.scheduler_timer = 0;
                cpu.dispatchScheduler();
            } else if (cpu.state->c == 2 && mutex == 1) { // sender
                cpu.memory->physicalAt(address) = 0;
                cpu.memory->physicalAt(address + 2)++; // increase full semaphore
                cpu.scheduler_timer = 0;
                cpu.dispatchScheduler();
            }
            break;
        }
        default:
        {
            cout << "Wrong input!!!\n";
        }
    }

    return 0;
}