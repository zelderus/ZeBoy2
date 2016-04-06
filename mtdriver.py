##
##	Драйвер работы с дисплеями MT-12232A и аналогичными
##	ZeLDER
##		http://www.melt.com.ru/docs/MT-12232A.pdf
##

#
#	- работа с дисплеем
#		lcdInit()	- инициализация дисплея (драйвера)
#		lcdClear()	- очистка матрицы и обновление дисплея
#		lcdDraw()	- обновление дисплея данными из матрицы
#		lcdSetPins(a0, rw, e, res, cs, d0, d1, d2, d3, d4, d5, d6, d7)	- распиновка Raspberry
#
#	- работа с матрицой	
#		mtxClearMatrix()		- очистка матрицы (без обновления дисплея)
#		mtxPutPixel(x, y, bit)	- помещение пикселя в матрицу (без вывода на экран)
#

#
# Пример:
#	import mtdriver as mt
#	def setup():
#		mt.lcdInit()  				#инициализация
#		mt.lcdClear() 				#очистка экрана
#	def loop():
#		mt.mtxClearMatrix() 		#очистка матрицы
#		mt.mtxPutPixel(1, 1, 1) 	#рисуем в матрицу
#		#..
#		mt.lcdDraw()				#рендер конечной картинки на экран

#
# Распиновка (default) для RaspberryPi 2
# A0 	= 4
# RW 	= 17
# E 	= 27
# RES 	= 22
# CS 	= 25
# db0 	= 18
# db1 	= 23
# db2 	= 24
# db3 	= 12
# db4 	= 6
# db5 	= 13
# db6 	= 19
# db7 	= 26
#




import RPi.GPIO as GPIO
import time


# ...
__mtlcd_pagesize = 8
__mtlcd_pagecount = 4
__mtlcd_width = 122
__mtlcd_heigth = 32



#
#	Работа с дисплеем
#

# инициализация дисплея (драйвера)
def lcdInit():
	s_setup()
	s_lcdInit()
	__lcd_matrix = [[0 for x in range(__mtlcd_width)] for x in range(__mtlcd_pagecount)] 
	return 0

# распиновка Raspberry
def lcdSetPins(a0, rw, e, res, cs, d0, d1, d2, d3, d4, d5, d6, d7):
	_p_a0 = a0
	_p_rw = rw
	_p_e = e
	_p_res = res
	_p_cs = cs
	_db0 = d0
	_db1 = d1
	_db2 = d2
	_db3 = d3
	_db4 = d4
	_db5 = d5
	_db6 = d6
	_db7 = d7
	return 0

# очистка матрицы и обновление дисплея
def lcdClear():
	mtxClearMatrix()
	lcdDraw()
	return 0

# обновление дисплея данными из матрицы
def lcdDraw():
	s_lcdDraw()
	return 0



#
#	Работа с матрицой
#

__lcd_matrix = [[0 for x in range(4)] for x in range(122)] 
def _checkPixelRange(x, y):
	if (x < 0 or x >= __mtlcd_width or y < 0 or y >= __mtlcd_heigth):
		return False
	return True

# очистка матрицы
def mtxClearMatrix():
	for y in range(0, __mtlcd_pagecount):
		for x in range(0, __mtlcd_width):
			__lcd_matrix[x][y] = 0x00
	return 0

# помещение пикселя в матрицу (будет выведен при обновлении дисплея)
def mtxPutPixel(x, y, bit):
	if (_checkPixelRange(x, y)==False):
		return 0
	if (bit):
		__lcd_matrix[x][int(y / __mtlcd_pagesize)] |= 1 << (y % 8);
	else:
		__lcd_matrix[x][int(y / __mtlcd_pagesize)] &= 0 << (y % 8);




#################################
#								
#			 system
#
#


_p_a0 = 4
_p_rw = 17
_p_e = 27
_p_res = 22
_p_cs = 25

_db0 = 18
_db1 = 23
_db2 = 24
_db3 = 12
_db4 = 6
_db5 = 13
_db6 = 19
_db7 = 26


# инициализация Пинов с Распберри
def s_setup():
##    GPIO.setmode(GPIO.BOARD)
	GPIO.setmode(GPIO.BCM)
	GPIO.setwarnings(False)
	# data
	s_dataLineToOut()
	# com
	GPIO.setup(_p_a0, GPIO.OUT)
	GPIO.setup(_p_rw, GPIO.OUT)
	GPIO.setup(_p_e, GPIO.OUT)
	GPIO.setup(_p_res, GPIO.OUT)
	GPIO.setup(_p_cs, GPIO.OUT)

# Пины данных включаем на выход (передаем на дисплей данные)
def s_dataLineToOut():
	GPIO.setup(_db0, GPIO.OUT)
	GPIO.setup(_db1, GPIO.OUT)
	GPIO.setup(_db2, GPIO.OUT)
	GPIO.setup(_db3, GPIO.OUT)
	GPIO.setup(_db4, GPIO.OUT)
	GPIO.setup(_db5, GPIO.OUT)
	GPIO.setup(_db6, GPIO.OUT)
	GPIO.setup(_db7, GPIO.OUT)
# на вход из дисплея данные
def s_dataLineToIn():
	GPIO.setup(_db0, GPIO.IN)
	GPIO.setup(_db1, GPIO.IN)
	GPIO.setup(_db2, GPIO.IN)
	GPIO.setup(_db3, GPIO.IN)
	GPIO.setup(_db4, GPIO.IN)
	GPIO.setup(_db5, GPIO.IN)
	GPIO.setup(_db6, GPIO.IN)
	GPIO.setup(_db7, GPIO.IN)
    
    
def s_delayMs(ms):
	time.sleep(ms/1000.0)

def s_delayUs(us):
	time.sleep(us/1000000.0)

def s_delayNs(ns):
	time.sleep(ns/1000000000.0)



# подача напряжения (лог 1 или 0) на Пины
def s_mtA0(b):
	GPIO.output(_p_a0, GPIO.HIGH if b > 0 else GPIO.LOW)
def s_mtRW(b):
	GPIO.output(_p_rw, GPIO.HIGH if b > 0 else GPIO.LOW)
def s_mtE(b):
	GPIO.output(_p_e, GPIO.HIGH if b > 0 else GPIO.LOW)
def s_mtRES(b):
	GPIO.output(_p_res, GPIO.HIGH if b > 0 else GPIO.LOW)
def s_mtCS(b):
	GPIO.output(_p_cs, GPIO.HIGH if b > 0 else GPIO.LOW)
def s_mtData(b):
	GPIO.output(_db7, GPIO.HIGH if b&128>0 else GPIO.LOW)
	GPIO.output(_db6, GPIO.HIGH if b&64>0 else GPIO.LOW)
	GPIO.output(_db5, GPIO.HIGH if b&32>0 else GPIO.LOW)
	GPIO.output(_db4, GPIO.HIGH if b&16>0 else GPIO.LOW)
	GPIO.output(_db3, GPIO.HIGH if b&8>0 else GPIO.LOW)
	GPIO.output(_db2, GPIO.HIGH if b&4>0 else GPIO.LOW)
	GPIO.output(_db1, GPIO.HIGH if b&2>0 else GPIO.LOW)
	GPIO.output(_db0, GPIO.HIGH if b&1>0 else GPIO.LOW)
	return 0
def s_mtGetData():
	v = 0
	b1 = GPIO.input(_db3);
	mask = 1 << 3
	v |= mask if b1 else 0
	b2 = GPIO.input(_db2);
	mask = 1 << 2
	v |= mask if b2 else 0
	b3 = GPIO.input(_db1);
	mask = 1 << 1
	v |= mask if b3 else 0
	b4 = GPIO.input(_db0);
	mask = 1 << 0
	v |= mask if b4 else 0
	b5 = GPIO.input(_db7);
	mask = 1 << 7
	v |= mask if b5 else 0
	b6 = GPIO.input(_db6);
	mask = 1 << 6
	v |= mask if b6 else 0
	b7 = GPIO.input(_db5);
	mask = 1 << 5
	v |= mask if b7 else 0
	b8 = GPIO.input(_db4);
	mask = 1 << 4
	v |= mask if b8 else 0
	return v


# запись байта данных в дисплей (установка нужных сигналов и прочее)
def s_writeByte(b, cd, lr):
	s_mtRW(0)
	s_mtA0(cd)
	s_mtCS(lr)
	s_mtData(b)
	s_delayNs(40.0)	#>40
	s_mtE(0)
	s_delayNs(160.0)	#>160
	s_mtE(1)
	s_delayNs(200.0 - 40.0 - 160.0) #2000.0 - 40.0 - 160.0
def s_writeCodeL(b):
	s_writeByte(b, 0, 1)
def s_writeCodeR(b):
	s_writeByte(b, 0, 0)
def s_writeDataL(b):
	s_writeByte(b, 1, 1)
def s_writeDataR(b):
	s_writeByte(b, 1, 0)

# чтение байта данных от дисплея
def s_readByte(cd, lr, rw):
	b = 0
	s_dataLineToIn()
	s_mtRW(rw)
	s_mtA0(cd)
	s_mtCS(lr)
	s_delayNs(50.0) #> 40
	s_mtE(0)
	s_delayNs(350.0) #> 300
	b = s_mtGetData()
	s_mtE(1)
	s_delayNs(2000.0 - 50.0 - 350.0)
	s_dataLineToOut()	# restore
	return b
def s_readDataL():
	return s_readByte(1, 1, 1)
def s_readDataR():
	return s_readByte(1, 0, 1)
def s_readStatusL():
	return s_readByte(1, 1, 0)
def s_readStatusR():
	return s_readByte(1, 0, 0)


# инициализация дисплея
def s_lcdInit():
	s_mtE(1)
	s_mtRES(0)
	s_delayUs(12.0) #>10
	s_mtRES(1)
	s_delayMs(2.5)	#>1
	s_writeCodeL(0xE2) # reset
	s_writeCodeR(0xE2)
	s_writeCodeL(0xEE) # end (reset rmw)
	s_writeCodeR(0xEE)
	#s_writeCodeL(0xE0) # rwm
	#s_writeCodeR(0xE0)
	s_writeCodeL(0xA4) # static off
	s_writeCodeR(0xA4)
	s_writeCodeL(0xA9) # duty select
	s_writeCodeR(0xA9)
	s_writeCodeL(0xC0) # display start line
	s_writeCodeR(0xC0)
	s_writeCodeL(0xA1) #
	s_writeCodeR(0xA0) #
	s_writeCodeL(0xAF) # display on
	s_writeCodeR(0xAF)
	# disable
	#s_writeCodeL(0xAE)
	#s_writeCodeR(0xAE)


# статус дисплея
def s_lcdStatusView(b):
	print("Busy: " + (str(1 if b&128>0 else 0)) + ", ADC: " + (str(1 if b&64>0 else 0)) + ", ON/OFF: " + (str(1 if b&32>0 else 0)) + ", RESET: " + (str(1 if b&16>0 else 0)))	
def s_lcdStatus():
	b = 0
	b = s_readStatusL()
	s_showByte(b, "Status Left")
	s_lcdStatusView(b)
	b = s_readStatusR()
	s_showByte(b, "Status Right")
	s_lcdStatusView(b)
	return 0


# вывод на дисплей из массива данных. 
# проход по всем страницам, по всей ширине двух кристалов.
def s_lcdDraw():
	for p in range(0,4):
		# set address
		s_writeCodeL(p|0xB8)
		s_writeCodeL(0x13)
		# draw
		for c in range(0, 61):
			s_writeDataL(__lcd_matrix[c][p])
		# set address
		s_writeCodeR(p|0xB8)
		s_writeCodeR(0x00)
		# draw
		for c in range(61, 122):
			s_writeDataR(__lcd_matrix[c][p])
	return 0

