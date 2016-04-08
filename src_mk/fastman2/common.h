#ifndef ADD_CMMM
#define ADD_CMMM

//
// types
//
typedef unsigned char BYTE;
typedef unsigned int BOOL;
#define TRUE 1
#define FALSE 0

//
// bits
//
int SetBit(int x,int y);
int ClrBit(int x,int y);
int ToggleBit(int x,int y);

//
// times
//
void nop();
void delay(unsigned int p);
void delay1000(unsigned int p);
void delayMs(unsigned int p);
void delayUs(unsigned int p);
void delayNs(unsigned int p);



#endif