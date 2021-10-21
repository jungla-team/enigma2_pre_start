# Changelog

## [5.9] - 21/10/2021

- Bug fixes
- Se deja de dar soporte a TDTChannels y PlutoTV para usar los plugins asociados

## [5.8] - 23/03/2021

- Corregido bug que en algunos casos borraba la lista de canales cuando arrancaba el deco sin conexión a Internet

## [5.7] - 03/03/2021

- Corregido bug a la hora de escribir en el log la traza de los picons 3d
- Corregido bug que en algunos casos con cortes de luz se borraban los canales al arrancar

## [5.6] - 01/03/2021

- Añadidos soporte para picons TIPOPICON=movistar-color-3d
- https://github.com/jungla-team/Picon-enigma2-Movistar/tree/main/jungle-picon-Movistar-color-3d/picon

## [5.5] - 14/02/2021

- Añadidas listas de hispasat para que se actualicen a través del script con el parámetro LISTA_CANALES (astra-hispasat, astra-hotbird-hispasat)

## [5.4] - 02/02/2021

- Bouquets incluídos de save_bouquets, bouquets IPTV y TDT ahora aparecerán al principio de la lista
- Arreglado bug con el fichero save_bouquets

## [5.3] - 29/01/2021

- Arreglado bug con el fichero fav_bouquets

## [5.2] - 28/01/2021

- Añadida opción para cargar picons en color (TIPOPICON=movistar-color)
- Limpieza de archivos de PLUTOTV o TDTCHANNELS si están activados y después se desactivan

## [5.1] - 22/01/2021

- Incluído bouquet enigma2 para PlutoTV - https://pluto.tv

## [5.0] - 26/12/2020

- Incluido bouquet enigma2 para Tdtchannels.tv - https://github.com/LaQuay/TDTChannels
- Opción de no borrar los favoritos que deseamos usando el fichero /etc/enigma2/save_bouquets
- Añadidas dependencias de bash y curl en la instalación

## [4.10] - 18/12/2020

- Corrección de errores

## [4.9] - 14/12/2020

- Corrección para que genere el fichero de log

## [4.8] - 14/12/2020

- Adaptaciones para que las descargas de paquetes funcionen en OpenPLI 8.0
- Mejoras en la instalación del paquete rsync 

## [4.7] - 29/10/2020

- Añadidas opciones de chequeo y upgrade desde nuestro servidor feed

## [4.6] - 25/10/2020

- Cambiadas las url para que actualicen desde nuestro servidor feed

## [4.5] - 18/10/2020

- Añadido nuevo parametro TIPOPICON para elegir el tipo de picon (TIPOPICON=movistar-original o TIPOPICON=movistar-lunar)
- Cambiados los umbrales de espacio a 15MB sin disco hdd y a 30MB con disco
- Mejora en la descarga de los picons para que únicamente decargue los necesarios
- Cambiadas descargas de todos los ficheros a nuestro server evitando así las descargas desde github

## [4.4] - 07/10/2020

- Mejora en la comprobación de versión
- Mejora para el envío de mensajes de telegram

## [4.3] - 08-09-2020

- Mejora en la comprobación/corrección del fichero de configuración
- Corrección en el aviso de espacio ocupado en la ruta donde están instalados los picons

## [4.2] - 14-08-2020

- Eliminación en el fichero de configuración de retornos de carro de Windows y líneas en blanco

## [4.1] - 14-08-2020

- Fix en la sincronización de los picons cuando hay novedades

## [4.0] - 10-08-2020

- Ampliación del margen de espacio para la descarga de picons en el caso de no tener disco hdd ni usb montados 
- Añadido parámetro PICONS en el fichero de configuración (enigma2_pre_start.conf) para descarga de picons (0 - descarga lista únicamente, 1 - lista y picons)

## [3.5] - 07-08-2020

- Quitada la opción de actualización del junglebot, ya que el bot se puede actualizar con el propio bot y vía ipk
- Envío de mensajes al bot únicamente si el bot está activo

## [3.4] - 02-07-2020

- Añadida mejora para controlar el espacio tanto en /tmp como en la ruta donde se tengan los picons. Si no hubiera disponibles 30MB no descarga los picons
- Añádida descarga de picons desde el servidor de jungle-team en vez desde github (por problemas de conexión y lentitud hacia github detectados)

## [3.3] - 10-05-2020

- Añadida instalación de requisitos pip para el junglebot de Telegram
- Añadida variable de versión 

## [3.2] - 02-05-2020

- Fix en la parada del bot cuando hay que actualizarlo
- Añádida creación del fichero de configuración si no existe

## [3.1] - 15-03-2020

- Fix en la autoupdate de enigma2_pre_start.sh

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
