#include <iostream>
#include "8080emuCPP.h"
#include "gtuos.h"
#include <string>

using namespace std;

GTUOS::GTUOS() : hp(0x0F00) {
    out.open("output.txt");
    in.open("input.txt");
}
GTUOS::~GTUOS(){
    out.close();
    in.close();
}

uint64_t GTUOS::handleCall(const CPU8080 & cpu) {

    unsigned char type = cpu.state->a;

    switch (type) {
        case PRINT_B:
        {
            out << (int) cpu.state->b;
            break;
        }
        case PRINT_MEM:
        {
            uint32_t offset = (cpu.state->b << 8) | cpu.state->c;
            out << (int) cpu.memory->at(offset)<<endl;
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
            getline(in,str);  
            for(int i=0;i <str.size();++i){
                cpu.memory->at(hp) =str[i];
                ++hp;
            }
            cpu.memory->at(hp) ='\0';
            ++hp;
            
            break;
        }
        default:
        {
            out<<"Wrong input!!!";
        }
    }

    return 0;
}

