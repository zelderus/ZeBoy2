# ZeBoy 2
Hard-проект. 
Последовательное создание портативной консоли.
[Справочник-описание][lnk_help].

Цель
--------
- Изучение RaspberryPi
- Изучение основ электротехники
- Применение внешних дисплеев. Работа на самом низком уровне
- Программирование микроконтроллеров

Применяемое железо
--------
- RaspberryPi 2 (написание кода, программатор)
- Кучка транзисторов, резисторов и прочего
- LCD MT-12232A
- Atmel AT89C51RC
- UT62256CPCL



Программы под RPi
----------
Лежат в папке `src_rpi`. Предназначены для запуска с RaspberryPi2. Как правило в каждом файле указано к каким пинам подключать конкретное устройство.
- ut62256.py - programm for using external RAM (only 6 bit addr bus)


Программы под MK
----------
Лежат в папке `src_mk`. Предназначены для прошивки на микроконтроллер.
- mkram.asm (.hex, .bin) программа (драйвер) для МК (AT89C51RC) для работы с SRAM (UT62256CPCL)
- папка 'fastman2' содержит проект на языке ASM - игра для МК (AT89C51RC)


[lnk_help]: <http://zedk.ru/ss/zeboy2/index.html>
