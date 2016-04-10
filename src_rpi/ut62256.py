
#
#	Programm for work with UT62256 by RaspberryPi2
#	for example (and for economy RPi pins) use only 6 bit addr bus
#	ZeLDER
#

#
#	Functions:
#		pinInit()
#		writeByte(addr, b)
#		readByte(addr)

#
#	Example:
#		import ut62256 as rmm
#		def initAndWrite():
#			rmm.pinInit()
#			rmm.writeByte(0x00, 0xAA)
#			rmm.writeByte(0x01, 0xFF)
#		initAndWrite()
#		b = rmm.readByte(0x01) # out: b=0xFF
#

import RPi.GPIO as GPIO
import time
import binascii


# pins
_we	= 12
_ce 	= 18
_oe 	= 23

# addr bus
_p3_0 = 4
_p3_1 = 17
_p3_2 = 27
_p3_3 = 22
_p3_4 = 25
_p3_5 = 24
#_p3_6 = 
#_p3_7 = 

# data bus
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
def pinInit():
	_setupPins()
	_downAllPins()
	print("inited")
	return 0










# setup
def _setupPins():
	##    GPIO.setmode(GPIO.BOARD)
	GPIO.setmode(GPIO.BCM)
	GPIO.setwarnings(False)
	# com
	GPIO.setup(_we, GPIO.OUT)
	GPIO.setup(_ce, GPIO.OUT)
	GPIO.setup(_oe, GPIO.OUT)
	#
	_dataLineToOut()
	# addr bus (only 6 bit for test)
	GPIO.setup(_p3_0, GPIO.OUT)
	GPIO.setup(_p3_1, GPIO.OUT)
	GPIO.setup(_p3_2, GPIO.OUT)
	GPIO.setup(_p3_3, GPIO.OUT)
	GPIO.setup(_p3_4, GPIO.OUT)
	GPIO.setup(_p3_5, GPIO.OUT)
	#GPIO.setup(_p3_6, GPIO.OUT)
	#GPIO.setup(_p3_7, GPIO.OUT)
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


def _setWe(b):
	GPIO.output(_we, GPIO.HIGH if b > 0 else GPIO.LOW)
def _setOe(b):	
	GPIO.output(_oe, GPIO.HIGH if b > 0 else GPIO.LOW)
def _setCe(b):
	GPIO.output(_ce, GPIO.HIGH if b > 0 else GPIO.LOW)


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


def _setAddr(b):
	#GPIO.output(_p1_7, GPIO.HIGH if b&128>0 else GPIO.LOW)
	#GPIO.output(_p1_6, GPIO.HIGH if b&64>0 else GPIO.LOW)
	GPIO.output(_p3_5, GPIO.HIGH if b&32>0 else GPIO.LOW)
	GPIO.output(_p3_4, GPIO.HIGH if b&16>0 else GPIO.LOW)
	GPIO.output(_p3_3, GPIO.HIGH if b&8>0 else GPIO.LOW)
	GPIO.output(_p3_2, GPIO.HIGH if b&4>0 else GPIO.LOW)
	GPIO.output(_p3_1, GPIO.HIGH if b&2>0 else GPIO.LOW)
	GPIO.output(_p3_0, GPIO.HIGH if b&1>0 else GPIO.LOW)


def _downAllPins():
	print("down all pins")
	_setWe(0)
	_setCe(0)
	_setOe(0)

	_setData(0)
	return 0


def resetByte():
	_dataLineToOut()
	_setData(0x00)
	return 0



def writeByte(addr, b):
	_dataLineToOut()
	_setAddr(addr)	
	_setCe(0) #
	_setData(b)
	_setWe(0) #
	_delayUs(10.0) ###
	_setWe(1) #
	_setCe(1) #
	return 0

def readByte(addr):
	b = 0x00
	_dataLineToIn()
	_setAddr(addr)
	_setCe(0) #
	_setOe(0) #
	_delayUs(10.0) ###
	b = _getData()
	_setOe(1) #
	_setCe(1) #
	return b


#
# Example
#
#pinInit();
#writeByte(0x01, 0xFE)
#writeByte(0x02, 0x55)
#writeByte(0x03, 0xAA)
#resetByte()
#bd = 0
#bd = readByte(0x01)
#print("data: " + str(hex(bd)))
#bd = readByte(0x02)
#print("data: " + str(hex(bd)))
#bd = readByte(0x03)
#print("data: " + str(hex(bd)))



