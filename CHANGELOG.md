# Changelog

## [3.0] - 14-03-2020

- Añadida función para no instalar los bouquets que se indiquen el fichero /etc/enigma2/fav_bouquets
- Posibilidad de elegir que lista de canales instalar: astra, astra-hotbird o astra-comunitaria a través del fichero /usr/bin/enigma2_pre_start.conf

## [2.4] - 26-01-2020

- Fix en el borrado del fichero streamTDT.tv
- Conservación de ficheros de favoritos si tienen añadidos canales distintos a los del fichero de github

## [2.3] - 18-01-2020

- Cambio de ruta de descarga de zips a directorio temporal directamente
- Añadida limpieza del log de rsync de picons al inicio

## [2.2] - 06-01-2020

- Control errores de resolución del host de raw.githubusercontent.com (wget: unable to resolve host address raw.github...)
- Añadida funcionalidad para no borrar bouquets que tengan favoritos IPTV

## [2.1] - 03-01-2020

- Arreglado bug con creación de picons en la ruta /media/hdd
- Añadido mezclado de canales tdt cuando se realiza la instalación de canales por primera vez
- Añadida funcionalidad para no borrar bouquets que tengan favoritos TDT
    
## [2.0] - 28-12-2019

- Auto-actualización del script junglescript (enigma2_pre_start.sh)
- Actualización en el arranque/reinicio del bot de telegram después de una actualización
- Actualización en el borrado de bouquets de la lista de canales

## [1.3] - 20-12-2019

- Si el fichero lamedb tiene entradas de TDT, se actualiza el script para ponga esas entradas una vez se haya actualizado la lista de canales
- Actualización bug instalando rsync en CPUs Mipsel

## [1.2] - 01-12-2019

- Arreglados problemas con el log
- Arreglados problemas con funciones de copiado

## [1.1] - 20-11-2019

- Añadida actualización de junglebot de Telegram - https://github.com/jungla-team/junglebot

## [1.0] - 11-10-2019

- Añadida actualización de picons
- Añadida actualización de lista de canales Movistar
