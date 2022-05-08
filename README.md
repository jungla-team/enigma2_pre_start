# enigma2_pre_start <a href="https://www.paypal.me/jungleteam" rel="nofollow"><img src="https://camo.githubusercontent.com/d5d24e33e2f4b6fe53987419a21b203c03789a8f/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f446f6e6174652d50617950616c2d677265656e2e737667" alt="Donate" data-canonical-src="https://img.shields.io/badge/Donate-PayPal-green.svg" style="max-width:100%;"></a></h1>

Se usa este script para actualizaciones de canales y de picons del proyecto de https://jungle-team.com/

Para poder usarlo lo único que hay que hacer es:

Descargar el fichero enigma2_pre_start.sh en la carpeta /usr/bin de nuestro decodificador enigma2 y añadir permisos de ejecución:

`chmod +x /usr/bin/enigma2_pre_start.sh`

Poniendo este script con este nombre conseguimos que en cada reinicio se ejecute antes de arrancar enigma2.sh.

Parámetros a configurar:

```
LISTACANALES=<listadecanales a elegir>
PICONS=<0 a 1> 
TIPOPICON=<tipodepicon a elegir>
TDTCHANNELS=<0 o 1>
PLUTOTV=<0 o 1>
```

LISTACANALES con uno de estos valores (astra, astra-hotbird, astra-comunitaria). 
PICONS con valor =1 para permitir que se descargue los picons e =0 para que no se los descargue.
TIPOPICON con uno de estos valores (movistar-original, movistar-lunar, movistar-color, movistar-color-3d)
TDTCHANNELS con valor =1 para permitir que se descargue el bouquet tdtchannels, y valor =0 para que no se lo descargue.
PLUTOTV con valor =1 para permitir que se descargue el bouquet plutotv, y valor =0 para que no se lo descargue.

Ejemplo de archivo de configuración:

```
LISTACANALES=astra-comunitaria
PICONS=1
TIPOPICON=movistar-original
TDTCHANNELS=1
PLUTOTV=1
```

Además de estos parámetros podemos elegir si no queremos que nos meta algún bouquet en concreto de la lista de canales por defecto. Para ello hay que crear el fichero /etc/enigma2/fav_bouquets y dentro meter en líneas separadas los bouquets que NO queremos que se nos carguen en el deco.

Ejemplo:

```
movistariplus
canalesdeportes
```

Además ahora podemos elegir qué bouquets favoritos queremos que se mantengan aunque haya actualizaciones, para ellos hay que crear el fichero /etc/enigma2/save_bouquets y dentro meter en líneas separadas los bouquets que queremos que se salven.

Ejemplo:

```
deportes
laliga
mibouquet
motos
...
```

Más documentación sobre el script en: https://jungle-team.com/junglescript-5-0-auto-instalador-lista-canales-y-picon-enigma2/