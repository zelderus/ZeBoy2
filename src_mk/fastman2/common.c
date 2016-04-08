#include <common.h>


int SetBit(int x, int y) { return x|=(1<<y);}
int ClrBit(int x, int y) {return x&=~(1<<y);}
int ToggleBit(int x, int y) {return x^=(1<<y);}


void nop()
{
	
}

void delay(unsigned int p)
{
	unsigned int i;
	for(i=0;i<p;i++)
	{
		//asm("NOP");
		nop();
	}
}

void delay1000(unsigned int p)
{
	while(p>0){delay(1000);p--;}
}

void delayMs(unsigned int p)
{
	// TODO
	p=1;
	while(p>0){delay(1);p--;}
}
void delayUs(unsigned int p)
{
	// TODO
	p=1;
	while(p>0){delay(1);p--;}
}
void delayNs(unsigned int p)
{
	// TODO
	p=1;
	while(p>0){delay(1);p--;}
}