##
##	Fake-Драйвер дисплея MT-12232A
##	Применяется только для отладки
##	ZeLDER
##



import time




#
#	Работа с дисплеем
#

# инициализация дисплея (драйвера)
def lcdInit():
	print("MT FAKE inited!!!")
	return 0

# распиновка Raspberry
def lcdSetPins(a0, rw, e, res, cs, d0, d1, d2, d3, d4, d5, d6, d7):
	return 0

# очистка матрицы и обновление дисплея
def lcdClear():
	return 0

# обновление дисплея данными из матрицы
def lcdDraw():
	print(".")
	return 0



#
#	Работа с матрицой
#

# очистка матрицы
def mtxClearMatrix():
	return 0

# помещение пикселя в матрицу (будет выведен при обновлении дисплея)
def mtxPutPixel(x, y, bit):
	return 0

