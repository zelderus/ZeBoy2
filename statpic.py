##
##	Вывод статической картинки RaspberryPi с использованием дисплея MT-12232A
##	простой пример
##	ZeLDER
##


import mtdriver as mt
#import mtfake as mt



def setup():
	mt.lcdInit()  	# инициализация
	mt.lcdClear()	# очистка экрана
	print("inited")
	return 0


#
# рисуем
#
def draw():

	# рисуем в матрицу
	mt.mtxPutPixel(1, 1, 1)
	mt.mtxPutPixel(1, 2, 1)
	mt.mtxPutPixel(1, 3, 1)
	mt.mtxPutPixel(1, 4, 1)
	mt.mtxPutPixel(1, 5, 1)
	mt.mtxPutPixel(1, 6, 1)

	# вывод на дисплей
	mt.lcdDraw()
	return 0







# go
setup()
draw()