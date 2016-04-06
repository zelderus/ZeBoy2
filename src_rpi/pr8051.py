
#
#	Programm for write data to AT89C2051 by RaspberryPi2
#	for PROGRAMMATOR PR8051.1
#	ZeLDER
#

#
#	Functions:
#		mkInit()	- Init (MUST first)
#		mkRead(fname)	- Read data from MK to file 'fname' ('log.txt')
#		mkWrite(fname)	- Erase MK and Write data to MK from file 'fname' ('prog.bin')
#		mkWriteByArr(bArr) - Erase MK and Write data to MK from array of bytes
#		mkErase()	- Erase all data from MK
#


#
#	Example:
#				import pr8051 as mk					# импорт драйвера программатора
#				def initAndWrite():
#					mk.mkInit()  					# инициализация
#					mk.mkWrite("mktolcd.bin")		# запись
#				initAndWrite()
#

import RPi.GPIO as GPIO
import time
import binascii


# pins
_xl1	= 17
_rst 	= 4
_p3_1 = 18
_p3_2 = 23
_p3_4 = 22
_p3_5_7 = 24
_p3_3 = 27

_p1_0 = 5
_p1_1 = 6
_p1_2 = 13
_p1_3 = 19
_p1_4 = 26
_p1_5 = 16
_p1_6 = 20
_p1_7 = 21




#
#	Init
#
def mkInit():
	_setupPins()
	_breakPin31()
	_setRstH()
	_downAllPins()
	print("inited")
	return 0


#
#	Read data from MK to file 'log.txt'
#
def mkRead(fname="log.txt"):
	_readFromMk(fname)
	return 0

#
#	Erase MK and Write data to MK from file 'prog.bin'
#
def mkWrite(fname="prog.bin"):
	_eraseMk()
	_loadData(fname)
	_writeToMk(_fb, _bts)
	return 0


#
#	Erase MK and Write data to MK from array of bytes
#
def mkWriteByArr(byteArr):
	_eraseMk()
	_loadDataByArr(byteArr)
	_writeToMk(_fb, _bts)
	return 0

#
#	Erase all data from MK
#
def mkErase():
	_eraseMk()
	return 0





# setup
def _setupPins():
	##    GPIO.setmode(GPIO.BOARD)
	GPIO.setmode(GPIO.BCM)
	GPIO.setwarnings(False)
	# com
	GPIO.setup(_xl1, GPIO.OUT)
	GPIO.setup(_rst, GPIO.OUT)
	#
	_dataLineToOut()
	#
	GPIO.setup(_p3_1, GPIO.IN)
	GPIO.setup(_p3_2, GPIO.OUT)
	GPIO.setup(_p3_3, GPIO.OUT)
	GPIO.setup(_p3_4, GPIO.OUT)
	GPIO.setup(_p3_5_7, GPIO.OUT)
	return 0

def _dataLineToOut():
	GPIO.setup(_p1_0, GPIO.OUT)
	GPIO.setup(_p1_1, GPIO.OUT)
	GPIO.setup(_p1_2, GPIO.OUT)
	GPIO.setup(_p1_3, GPIO.OUT)
	GPIO.setup(_p1_4, GPIO.OUT)
	GPIO.setup(_p1_5, GPIO.OUT)
	GPIO.setup(_p1_6, GPIO.OUT)
	GPIO.setup(_p1_7, GPIO.OUT)
def _dataLineToIn():
	GPIO.setup(_p1_0, GPIO.IN)
	GPIO.setup(_p1_1, GPIO.IN)
	GPIO.setup(_p1_2, GPIO.IN)
	GPIO.setup(_p1_3, GPIO.IN)
	GPIO.setup(_p1_4, GPIO.IN)
	GPIO.setup(_p1_5, GPIO.IN)
	GPIO.setup(_p1_6, GPIO.IN)
	GPIO.setup(_p1_7, GPIO.IN)

def _delayMs(ms):
	time.sleep(ms/1000.0)
def _delayUs(us):
	time.sleep(us/1000000.0)
def _delayNs(ns):
	time.sleep(ns/1000000000.0)


def _setRst(b):
	GPIO.output(_rst, GPIO.HIGH if b == 0 else GPIO.LOW) # transistor invert
def _setXl1(b):
	GPIO.output(_xl1, GPIO.HIGH if b == 0 else GPIO.LOW) # transistor invert
def _setPin(pin, b):
	GPIO.output(pin, GPIO.HIGH if b > 0 else GPIO.LOW)

def _setData(b):
	GPIO.output(_p1_7, GPIO.HIGH if b&128>0 else GPIO.LOW)
	GPIO.output(_p1_6, GPIO.HIGH if b&64>0 else GPIO.LOW)
	GPIO.output(_p1_5, GPIO.HIGH if b&32>0 else GPIO.LOW)
	GPIO.output(_p1_4, GPIO.HIGH if b&16>0 else GPIO.LOW)
	GPIO.output(_p1_3, GPIO.HIGH if b&8>0 else GPIO.LOW)
	GPIO.output(_p1_2, GPIO.HIGH if b&4>0 else GPIO.LOW)
	GPIO.output(_p1_1, GPIO.HIGH if b&2>0 else GPIO.LOW)
	GPIO.output(_p1_0, GPIO.HIGH if b&1>0 else GPIO.LOW)
	return 0

def _getData():
	v = 0
	b1 = GPIO.input(_p1_3);
	mask = 1 << 3
	v |= mask if b1 else 0
	b2 = GPIO.input(_p1_2);
	mask = 1 << 2
	v |= mask if b2 else 0
	b3 = GPIO.input(_p1_1);
	mask = 1 << 1
	v |= mask if b3 else 0
	b4 = GPIO.input(_p1_0);
	mask = 1 << 0
	v |= mask if b4 else 0
	b5 = GPIO.input(_p1_7);
	mask = 1 << 7
	v |= mask if b5 else 0
	b6 = GPIO.input(_p1_6);
	mask = 1 << 6
	v |= mask if b6 else 0
	b7 = GPIO.input(_p1_5);
	mask = 1 << 5
	v |= mask if b7 else 0
	b8 = GPIO.input(_p1_4);
	mask = 1 << 4
	v |= mask if b8 else 0
	return v

def _breakPin31():
	GPIO.setup(_p3_1, GPIO.OUT)
	GPIO.output(_p3_1, GPIO.LOW)
	GPIO.setup(_p3_1, GPIO.IN)
def _getPin31():
	return GPIO.input(_p3_1)
def _downAllPins():
	print("down all pins")
	_setRstH()
	_setPin(_xl1, 0)
	#_setPin(_p3_1, 0) #only input
	_setPin(_p3_2, 0)
	_setPin(_p3_4, 0)
	_setPin(_p3_5_7, 0)
	_setPin(_p3_3, 0)
	_setPin(_p1_0, 0)
	_setPin(_p1_1, 0)
	_setPin(_p1_2, 0)
	_setPin(_p1_3, 0)
	_setPin(_p1_4, 0)
	_setPin(_p1_5, 0)
	_setPin(_p1_6, 0)
	_setPin(_p1_7, 0)
	return 0
def _setRstH():
	_setPin(_rst, 1)
def _setRst12():
	_setPin(_rst, 0)


def _setModeWrite():
	_setPin(_p3_3, 0)
	_setPin(_p3_4, 1)
	_setPin(_p3_5_7, 1)
	return 0
def _setModeErase():
	_setPin(_p3_3, 1)
	_setPin(_p3_4, 0)
	_setPin(_p3_5_7, 0)
	return 0
def _setModeRead():
	_setPin(_p3_3, 0)
	_setPin(_p3_4, 0)
	_setPin(_p3_5_7, 1)
	return 0

#
# Erase data from MK
#
def _eraseMk():
	print("SETTING for ERASE -> Vcc: 5V; V12: yes")
	print("-> erasing..")
	print("RST H")
	time.sleep(3.0)
	_setRst12()
	_delayMs(1.0) #==
	_setXl1(0)
	_delayMs(1.0) #==
	_setPin(_p3_2, 1)
	_delayMs(1.0) #==
	# mode: erase
	_setModeErase()
	_delayMs(1.0) #==
	# erase
	print("RST 12")	
	_setRst12() #!!
	#_delayMs(1.0) #==
	_setPin(_p3_2, 0)
	_delayMs(10.0)
	_setPin(_p3_2, 1)
	_delayMs(6.0) #==
	print("erase complete..")
	_downAllPins()
	time.sleep(2.0)
	return 0




def _writePulse():
	_setPin(_p3_2, 0)
	_delayMs(10.2)	
	_setPin(_p3_2, 1)

def _witeReady():
	wb = 0
	print(".", end="", flush=True)
	while(wb==0):
		wb = _getPin31()

def _nextAddr():
	_setXl1(1)
	#_delayMs(1.0)
	_setXl1(0)


#
# Write prog to MK
#
def _writeToMk(firstByte, bts):
	# data to write
	#_loadData(fname)
	print("SETTING for WRITE -> Vcc: 5V; V12: yes")
	print("-> writing..")
	print("RST LOW")
	time.sleep(3.0)
	#_setRst(0)	# RST to Low
	_delayMs(1.0) #==
	_setXl1(0)	# XL1 to Low
	_delayMs(1.0) #==
	_setRstH()	# High !!!# touch	
	print("RST H")
	time.sleep(3.0)
	_delayMs(1.0) #==
	_setPin(_p3_2, 1)
	_delayMs(1.0) #==
	# mode: write
	_setModeWrite()
	_delayMs(1.0) #==
	# set first byte
	_setData(firstByte)
	_delayMs(1.0) #==
	print("RST 12V")
	_setRst12()	# 12V
	_delayMs(1.0) #==
	# pulse
	_writePulse()
	# wait
	_witeReady()
	# next addr
	_nextAddr()
	for b in bts:
		# TODO: check if 0xFF then skip and do _nextAddr() only !!!!!
		# set data
		_setData(b)
		# pulse
		_writePulse()
		# wait
		_witeReady()
		# next addr
		_nextAddr()
	print(" ok")
	# power low
	print("power lowing..")
	time.sleep(1.0)
	_downAllPins()
	return 0


#
# Read data from MK to file
#
def _readFromMk(fname):
	print("SETTING for READ -> Vcc: 0!!; V12: not")
	print("-> reading..")
	print("Set RST to LOW")
	time.sleep(3.0)
	_setRstH()
	#_setRst(0)	# RST to Low
	_setXl1(0)	# XL1 to Low
	_dataLineToIn()
	_setPin(_p3_2, 1)
	_delayMs(1.0) #==
	# reset addr
	#_setPin(_rst, 0)
	_setRst12() # set 0
	_delayMs(1.0) #==
	_setRstH()
	print("Set RST to HIGH")
	time.sleep(3.0)
	_delayMs(1.0) #==
	# mode: read
	_setModeRead()
	_delayMs(1.0) #==
	log = open(fname, "w")
	for bb in range(0,2048):
		b = _getData()
		#print("read:"+str(hex(b)))
		log.write(str(hex(b))+" ")
		if (bb%3==0):
			log.write("\n")
		_nextAddr()
	log.flush()
	log.close()
	_dataLineToOut() # restore
	# power down
	_downAllPins()
	return 0



_fb = 0x00
_bts = []


#
# Load data from file
#
def _loadData(fname):
	global _fb, _bts
	_bts = []
	# read from file
	blocksize = 2048
	with open(fname, "rb") as f:
		#block = f.read(blocksize)
		block = f.read()
		#strp = ""
		#for ch in block:
		#	strp += hex(ch)+" "
		#print(strp)		
		sf = len(block)
		if (sf < 2):
			print("too short program")
			return 1
		# first byte
		#_fb = hex(block[0])
		_fb = block[0]
		# all other bytes
		for bn in range(1, sf):
			#_bts.append(hex(block[bn]))
			_bts.append(block[bn])
	return 0

#
# Load data from array
#
def _loadDataByArr(byteArr):
	global _fb, _bts
	_bts = []
	# read from file
	blocksize = 2048
	block = byteArr
	
	sf = len(block)
	if (sf < 2):
		print("too short program")
		return 1
	# first byte
	_fb = block[0]
	# all other bytes
	for bn in range(1, sf):
		_bts.append(block[bn])

	#_bts.append(0x02)
	#_bts.append(0x00)
	#_bts.append(0x03)
	#_bts.append(0x75)
	#_bts.append(0x90)
	#_bts.append(0x81) #!!!! LED
	#_bts.append(0x02)
	#_bts.append(0x00)
	#_bts.append(0x03)
	return 0
