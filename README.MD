Вычисление температуры окружающей среды и атмосферного давления с помощью датчика BMP180.
=====================
Модуль поддерживает 7 комманд управления датчиком BMP180
***
1. Комманда 4'h1 
Считывает калибровочные коээфициенты AC1-AC6, B1, B2, MB-MD по адресам регистров датчика с 0xAA по 0xBF и сохраняет в opm.v по адресам с 4'hA по 4'h0.
![readed calibration coefficients](https://github.com/MrNextor/BMP180/blob/main/doc/readed_calibration_coefficients.png)
2. Комманда 4'h2
Возвращает температуру окрущающей среды (temp in 0.1 oC) и атмосферного давления (press. in Pa) (oversampling_setting 0).
![readed uncompensated temperature value 16 bit](https://github.com/MrNextor/BMP180/blob/main/doc/readed_temp.png) 
3. Комманда 4'h3
Возвращает температуру окрущающей среды (temp in 0.1 oC) и атмосферного давления (press. in Pa) (oversampling_setting 1).
![readed uncompensated pressure value 19 bit](https://github.com/MrNextor/BMP180/blob/main/doc/readed_pressure.png)
4. Комманда 4'h4
Возвращает температуру окрущающей среды (temp in 0.1 oC) и атмосферного давления (press. in Pa) (oversampling_setting 2).
5. Комманда 4'h5
Возвращает температуру окрущающей среды (temp in 0.1 oC) и атмосферного давления (press. in Pa) (oversampling_setting 3).
6. Комманда 4'h6 
Производит soft reset BMP180, как при включении питания датчика.
7. Комманда 4'h7
Проверяет связь с датчиком. Датчик должен вернуть 0x55. В случае ошибки O_ERR установится в 1.