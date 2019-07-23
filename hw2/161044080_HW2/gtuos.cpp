#include <iostream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include "memory.h"
#include <time.h>
#include <string>

using namespace std;

GTUOS::GTUOS() : hp(0x0F00) {
    out = fopen("kernelOutput.txt", "w");
    in.open("input.txt");
    srand(time(NULL));
}

GTUOS::~GTUOS() {
    in.close();
    fclose(out);
}

void GTUOS::printContextSwitch(CPU8080& cpu) {
    if (*cpu.lastOpcode == 0xe9) {
        fprintf(out, "Context switch happened\n");
        int id = cpu.state->sp / 1024;
        int base = id * 1024;
        fprintf(out, "ID :%d\n", id);
        fprintf(out, "Base Register :%xH\n", base);
        fprintf(out, "Program Counter :%xH\n", cpu.state->pc);
        fprintf(out, "CC %c", cpu.state->cc.z ? 'z' : '.');
        fprintf(out, "%c", cpu.state->cc.s ? 's' : '.');
        fprintf(out, "%c", cpu.state->cc.p ? 'p' : '.');
        fprintf(out, "%c", cpu.state->cc.cy ? 'c' : '.');
        fprintf(out, "%c  ", cpu.state->cc.ac ? 'a' : '.');
        fprintf(out, "A $%02x B $%02x C $%02x D $%02x E $%02x H $%02x L $%02x SP %04x\n", cpu.state->a, cpu.state->b, cpu.state->c,
                cpu.state->d, cpu.state->e, cpu.state->h, cpu.state->l, cpu.state->sp);
    }

}

uint64_t GTUOS::handleCall(CPU8080 & cpu) {

    ofstream outf;
    int id = cpu.state->sp / 1024;
    if (0 < id && id < 11) {
        string str = "process"+to_string(id);
        outf.open(str, ios::out | ios::app);
    }
    unsigned char type = cpu.state->a;
    cpu.state->pc++;
    switch (type) {
        case PRINT_B:
        {
            outf << (int) cpu.state->b;
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
        case RANDOM_NUM:
        {
            cpu.state->b = rand() % 3 + 1;
            break;
        }
        default:
        {
            cout << "Wrong input!!!\n";
        }
        if(outf.is_open()){
            outf.close();
        }
    }

    return 0;
}
