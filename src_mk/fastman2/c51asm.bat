@echo off

set asmpath=D:/C51ASM
set propath=D:/Projects/zeboy2

cd %asmpath%/BIN/
c51asm %propath%/fastman2.asm -I %asmpath%/INC/at89c51rc2.inc --target at89c51rc2 --include %propath%/INC
pause
