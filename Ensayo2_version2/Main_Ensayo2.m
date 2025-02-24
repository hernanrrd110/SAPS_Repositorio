% Autores: Dragan Valeria, Hamnstrom Luis, RRD Hernan
% SAPS: 1er Cuatrimestre 2019
% 29-04-19
% ENSAYO 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
clc;
clear all;
close all;

fprintf('.....Informaci�n.....\r\n');
fprintf('.....Autores: Dragan Valeria, Hamnstrom Luis, RRD Hernan.....\r\n');
fprintf('.....Procesamiento de seniales de audio.....\r\n');

%...................... LECTURA DE LA SE�AL DE AUDIO ......................
% Cuadro de di�logo para abrir archivos, guarda nombre de archivo y direcci�n
[filename,pathname,~] = uigetfile('*.wav','Archivo de audio');
 
% Concatena direcci�n y nombre de archivo
file_senial = strcat(pathname,filename);
[vector_senial, frec_muestreo] = audioread(file_senial);

fprintf('.........Track AUDIO Seleccionado......... \r\n %s\r\n',filename);

%%
%..................... ACONDICIONAMIENTO DE LA SENIAL .....................

num_muestras = length(vector_senial);

vector_tiempo = 0:1/frec_muestreo:(num_muestras-1)/frec_muestreo;
%%%% Podemos usar tambien: linspace(0,1/frec_muestreo,0)

%%%%% Extraemos el valor medio de la senial %%%%%
vector_senial = vector_senial - mean(vector_senial);                                            

% sound(vector_senial,frec_muestreo);

%%
%..................... DETECCION Y SISTEMA DE ALARMA ......................

load('Coef_Butter_FiltroPasaBanda.mat');
load('Coef_Butter_FiltroPasaBajos.mat');
load('Coef_Butter_FiltroRechazaBanda.mat');

%%%% Filtrado inicial Pasa Banda
% . . . f corte inferior = 1200 Hz
% . . . f corte superior = 2700 Hz
% . . . Orden 6
% . . . Archivo: Butterworth-FiltroPasaBanda.fda/Coef_Butter_FiltroPasaBanda

vector_filtrado1 = filtfilt(Num_PasaBanda,Den_PasaBanda,vector_senial);
vector_filtrado1_= filtfilt(Num_RechazaBanda,Den_RechazaBanda,vector_filtrado1);

%%%% Rectificaci�n
% Permite obtener separar la modulante de la portadora
vector_filtrado2 = vector_filtrado1.^2;

%%%% Demodulacion
% Extraemos la modulante de la senial del silbido

%%%% Filtrado inicial Pasa Bajos
% . . . f corte inferior = 6 Hz
% . . . Orden 3
% . . . Archivo: Butterworth-Silbidos.fda/Coef_Butter_FiltroPasaBajos.mat
vector_filtrado3 = filter(Num_PasaBajos,Den_PasaBajos,vector_filtrado2);

%%% Comparacion
% Duracion minima de silbido, Duracion maxima de silbido, intervalo de
% tiempo entre silbidos para tomarlo que uno es consecutivo del otro

duracion_temporal_minima = 0.100; %[s]
duracion_temporal_maxima = 0.800; %[s]
intervalo_silbido_tiempo = 0.8; %[s]

[vector_activos] = Sistema_Deteccion(vector_filtrado3,frec_muestreo,...
    duracion_temporal_minima,duracion_temporal_maxima,intervalo_silbido_tiempo);

[vector_alarma] = Alarma(vector_activos,frec_muestreo);

vector_final = vector_senial + vector_alarma;
vector_final2 = vector_filtrado1 + vector_alarma;
sound(vector_final2,frec_muestreo);

% Filtrado RechazaBanda (Para sacar la alarma)
% . . . f corte inferior = 3000 Hz
% . . . f corte superior = 4000 Hz
% . . . Orden 4
% . . . Archivo: Butterworth-FiltroRechazaBanda.fda/Coef_Butter_FiltroRechazaBanda.mat

% Una vez tenemos la alarma, probamos el filtro Rechaza Banda para lograr
% quitarnos este sonido.

vector_final_filtrada = filtfilt(Num_RechazaBanda,Den_RechazaBanda,vector_final);

%%
%......................... CALCULO DE FFT AUDIO ..........................

FFT  = fft(vector_senial, num_muestras) / num_muestras;
% M�dulo de FFT
Modulo = 2*abs(FFT);

%%%%Nos quedamos con las frecuencias positivas
Modulo = Modulo(1:floor(num_muestras/2));
% vector frecuencias [Hz]
freq = frec_muestreo/2*linspace(0,1,floor(num_muestras/2));

%........................ CALCULO DE FFT FILTRADO .........................

Modulo_filtrado = 2*abs(fft(vector_filtrado3, num_muestras) / num_muestras);

%%%% Nos quedamos con las frecuencias positivas
Modulo_filtrado = Modulo_filtrado(1:floor(num_muestras/2));
% vector frecuencias [Hz]
freq_filtrado = frec_muestreo/2*linspace(0,1,floor(num_muestras/2));

%................... CALCULO FRECUENCIA FUNDAMENTAL .....................

%%%% Se us� esto para ver la frecuencia fundamental de un solo silbido del
%%%% sujeto de prueba

[M, orden_max] = max(Modulo); 
% orden_max es el indice donde encontro el maximo
frec_fund = freq(orden_max);   

%%
%.............................. GRAFICAS ...............................

%................. GRAFICACION senial
tamanio_titulo = 22;
tamanio_ejes = 18;

figure1 = figure ('Color',[1 1 1],'Name','Se�al Temporal Orginal','NumberTitle','off');
plot(vector_tiempo, vector_senial,'LineWidth',1);grid on;    

title('Se�al temporal de Audio Original','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

%................. GRAFICACION FFT senial
figure2 = figure ('Color',[1 1 1],'Name','FFT Audio Orginal','NumberTitle','off');
stem(freq, Modulo, 'b','LineWidth',1);grid on;

title('Espectro de Se�al de Audio Original','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Frecuencia [Hz]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Modulo','FontSize',tamanio_ejes,'FontName','Arial')

% %................. GRAFICACION senial filtrada
% 
% figure3 = figure ('Color',[1 1 1],'Name','Se�al Filtrada','NumberTitle','off');
% subplot(2,1,1);
% plot(vector_tiempo, vector_filtrado3,'LineWidth',1);grid on;    
% 
% title('Se�al con todos los filtrados','FontSize',tamanio_titulo,'FontName','Arial')
% xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
% ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

% %................. GRAFICACION FFT senial filtrada  ....................
% 
% subplot(2,1,2);
% stem(freq_filtrado, Modulo_filtrado, 'b','LineWidth',1);grid on;
% 
% title('Espectro Se�al Filtrada','FontSize',tamanio_titulo,'FontName','Arial')
% xlabel('Frecuencia [Hz]','FontSize',tamanio_ejes,'FontName','Arial')
% ylabel('Modulo filtrado','FontSize',tamanio_ejes,'FontName','Arial')

%............ GRAFICACION senial de entrada, alarma y combinada

figure4 = figure ('Color',[1 1 1],'Name','Se�ales Resultantes','NumberTitle','off');
subplot(4,1,1);
plot(vector_tiempo, vector_alarma,'LineWidth',1,'Color','g');grid on;

title('Se�al de Alarma','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

subplot(4,1,2);
plot(vector_tiempo, vector_senial,'LineWidth',1,'Color','r');grid on;

title('Se�al Original','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

subplot(4,1,3);
plot(vector_tiempo, vector_final,'LineWidth',1,'Color','b');grid on;  

title('Se�al Original + Alarma','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

subplot(4,1,4);
plot(vector_tiempo, vector_final_filtrada,'LineWidth',1,'Color','b');grid on;  

title('Se�al Original + Alarma con filtro','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')



%...................... Graficacion

figure ('Color',[1 1 1],'Name','Se�ales','NumberTitle','off');
subplot(3,1,1);
plot(vector_tiempo, vector_filtrado1,'LineWidth',1,'Color','g');grid on;

title('Primer Filtro','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

%sound(vector_filtrado1,frec_muestreo);

subplot(3,1,2);
plot(vector_tiempo, vector_filtrado2,'LineWidth',1,'Color','r');grid on;

title('Segundo Filtro','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

subplot(3,1,3);
plot(vector_tiempo, vector_filtrado3,'LineWidth',1,'Color','b');grid on;  

title('Tercer Filtro','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',tamanio_ejes,'FontName','Arial')
ylabel('Amplitud','FontSize',tamanio_ejes,'FontName','Arial')

............ GRAFICACION Vector Activos
figure6 = figure ('Color',[1 1 1],'Name','Se�al de activacion de Alarma','NumberTitle','off');
plot(vector_tiempo, vector_activos,'LineWidth',1,'Color','g');grid on;    
title('Se�al de Activacion','FontSize',tamanio_titulo,'FontName','Arial')
xlabel('Tiempo [seg]','FontSize',18,'FontName','Arial')
ylabel('Amplitud','FontSize',18,'FontName','Arial')






