##
##	Игра для RaspberryPi с использованием дисплея MT-12232A
##	проверка возможностей дисплея
##	ZeLDER
##


import mtdriver as mt
#import mtfake as mt
import time
import datetime as dt

import curses
window = curses.initscr()
window.nodelay(1)




_frameRateSec = 1.0/31 	# FPS

def setup():
	mt.lcdInit()  	# инициализация
	print("clear")
	mt.lcdClear()	# очистка экрана
	print("inited")
	return 0


_lastTime = 0.0

def start():
	global _lastTime, _L
	_lastTime = dt.datetime.now()
	loop() #go
	return 0


def loop():
	global _lastTime
	inGame = True
	while(inGame):
		try:
			mt.mtxClearMatrix()
			update()
			mt.lcdDraw()
			# timer fps
			now = dt.datetime.now()
			delta = (now -_lastTime).total_seconds()
			d = _frameRateSec - delta
			if (d > 0.0):
				time.sleep(d)
			_lastTime = dt.datetime.now()
		except KeyboardInterrupt:
			inGame = False
			print("\nexit game")
	return 0


#
# data
#

_xa = 0
_xpos = 0
_ch = 0

def input_thread(n):
	while(True):
		derp = input()
		print("itrhread: " + str(derp))
		n.append(derp)


def fixposX(x, withCycle):
	if x > 121:
		x = 0 if withCycle else 121
	if x < 0:
		x = 121 if withCycle else 0
	return x

def fixposY(y, withCycle):
	if y > 31:
		y = 0 if withCycle else 31
	if y < 0:
		y = 31 if withCycle else 0
	return y

#
# figures
#
def drawBlock3x3(x, y):
	for xx in range(0,3):
		for yy in range(0,3):
			mt.mtxPutPixel(x+xx, y+yy, 1)

def drawBlock6x6(x, y):
	for xx in range(0,6):
		for yy in range(0,6):
			mt.mtxPutPixel(x+xx, y+yy, 1)



_lastGetch = dt.datetime.now()
_lastCh = -1
#
# обновление логики игры
#
def update():
	global _xpos, _xa, _lastGetch, _lastCh

	# KEYS
	_ch = int(window.getch())
	delta = (dt.datetime.now() -_lastGetch).total_seconds()
	dStep = 0.02
	if (_ch == 97 and (_lastCh != _ch or delta >= dStep)):
		_xpos = _xpos - 1
	if (_ch == 115 and (_lastCh != _ch or delta >= dStep)):
		_xpos = _xpos + 1
	_lastCh = _ch
	_ch = 0
	_lastGetch = dt.datetime.now()
	#print(str(_ch))
	



	mt.mtxPutPixel(0, 1, 1) 	#рисуем
	mt.mtxPutPixel(0, 2, 1)
	mt.mtxPutPixel(0, 3, 1)
	mt.mtxPutPixel(0, 4, 1)
	mt.mtxPutPixel(0, 5, 1)
	mt.mtxPutPixel(0, 6, 1)

	# auto
	_xa = fixposX(_xa+1, True)
	drawBlock6x6(_xa, 16)

	# key
	_xpos = fixposX(_xpos, False)
	drawBlock6x6(_xpos, 9)
		

	return 0






if __name__ == "__main__" :
	# go
	setup()
	start()