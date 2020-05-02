# enigma2_pre_start

Se usa este script para actualizaciones del bot, de canales y de picons del proyecto de https://jungle-team.com/

Para poder usarlo lo único que hay que hacer es:

Añadir el fichero enigma2_pre_start.sh en la carpeta /usr/bin de nuestro decodificador enigma2 y añadir permisos de ejecución:

''chmod +x /usr/bin/enigma2_pre_start.sh

Poniendo este script con este nombre conseguimos que en cada reinicio se ejecute antes de arrancar enigma2.sh.

Podemos elegir qué lista de canales instalar creando este archivo de configuración: /usr/bin/enigma2_pre_start.conf y metiendo dentro la variable LISTACANALES con uno de estos valores (astra, astra-hotbird, astra-comunitaria). 

Ejemplo: LISTACANALES=astra

También podemos elegir si no que queremos que nos meta algún bouquet en concreto, para ello hay que crear el fichero /etc/enigma2/fav_bouquets y dentro meter en líneas separadas los bouquets que NO queremos que se nos carguen en el deco 

Ejemplo:

movistariplus
canalesdeportes

Más documentación sobre el script en: https://jungle-team.com/junglescript-lista-canales-y-picon-enigma2-movistar/
