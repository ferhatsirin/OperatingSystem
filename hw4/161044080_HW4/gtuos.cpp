#include <iostream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include "memory.h"
#include <time.h>
#include <string>

using namespace std;

GTUOS::GTUOS() : hp(0x0F00) {
    in.open("input.txt");
    contextSwitch.open("system.txt", ios::out | ios::trunc);
    srand(time(NULL));

    for (int i = 1; i < 4; ++i) {
        string str = "process" + to_string(i) + "-" + getName(i);
        outf.open(str, ios::out | ios::trunc);
        outf.close();
    }
    for(int i=0;i<4000;++i){
        arr[i] =rand()%256;
    }
    for(int i=0;i<3999;++i){
        for(int j=i+1;j<4000;++j){
            if(arr[j] > arr[i]){
                int t=arr[j];
                arr[j] =arr[i];
                arr[i] =t;
            }
        }
    }
}

GTUOS::~GTUOS() {
    in.close();
    contextSwitch.close();
}

void GTUOS::printContextSwitch(CPU8080& cpu) {
    if (cpu.state->pc == 0x56) {
        int id = cpu.state->sp / 16384;
        contextSwitch << "CSEVENT: Current_PID: " << id << " Current_PNAME: " << getName(id);
    }
    if (cpu.state->pc == 0x78) {
        int sp =(cpu.state->h << 8) | cpu.state->l;
        int id = sp/16384;
        contextSwitch << " Next_PID: " << id << " Next_PNAME: " << getName(id) << endl;
    }
}

string GTUOS::getName(int id) {
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

uint64_t GTUOS::handleCall(CPU8080 & cpu) {
    unsigned char type = cpu.state->a;
    cpu.state->pc++;
    int n = rand() % 10;
    int id = cpu.state->sp / 16384;
    if (0 < id && id < 11) {
        string str = "process" + to_string(id) + "-" + getName(id);
        outf.open(str, ios::out | ios::app);

    }

    switch (type) {
        case PRINT_B:
        {
            outf << (int) cpu.state->b;
            if(id != 2){
                outf<<endl;
            }
            break;
        }
        case PRINT_MEM:
        {
            uint32_t offset = (cpu.state->b << 8) | cpu.state->c;
            outf << (int) cpu.memory->at(offset) << endl;
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
            outf << str;
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
            int stack = startAddress + 16384;

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
            int id = cpu.state->sp / 16384;
            contextSwitch << "CSEVENT: Current_PID: " << id << " Current_PNAME: " << getName(id);
            break;
        }
        case SET_QUANTUM:
        {
            int t = cpu.state->b;
            cpu.setQuantum(t);
        }
        case RAND_INT:
        {
          //  cpu.state->b = rand() % 256;
            cpu.state->b =arr[index];
            ++index;
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
            int address = 0x2000 + 53 * (cpu.state->b - 1); // go to mailbox address
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
    if (outf.is_open()) {
        outf.close();
    }

    return 0;
}