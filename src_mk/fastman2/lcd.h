#ifndef ADD_LCD_MT12232A
#define ADD_LCD_MT12232A



void LCDinit(BOOL fromProt);
void LCDclear();
void LCDdraw(BYTE video[][122]);
void LCDdrawLeftOnly(BYTE video[][122]);


void LCD_A0(int b);
void LCD_CS(int b);
void LCD_SetD(int b);
void WriteByte(int b, bit cd, bit lr);
void WriteCodeL(int b);
void WriteCodeR(int b);
void WriteDataL(int b);
void WriteDataR(int b);


#endif