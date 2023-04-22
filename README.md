![jungle_script](https://user-images.githubusercontent.com/44529886/233775362-c6eedd97-5dd2-4dd5-a86e-e4d4f36c587e.png)

![shell](https://user-images.githubusercontent.com/44529886/233772260-c382c7f5-3f2b-4eb0-a828-5f808b930373.png)
[   ![Licencia Junglebot](https://jungle-team.com/wp-content/uploads/2023/03/licence.png)
](https://github.com/jungla-team/junglebot/blob/master/LICENSE) [![chat telegram](https://jungle-team.com/wp-content/uploads/2023/03/telegram.png)
](https://t.me/joinchat/R_MzlCWf4Kahgb5G) [![donar a jungle](https://jungle-team.com/wp-content/uploads/2023/03/donate.png)
](https://paypal.me/jungleteam)

Hemos realizado un script shell denominado `junglescript` ejecutable para receptores enigma2, que permite la gestion de instalacion de listas canales y picones de los que realizamos en jungle-team, de una manera automatizada. ¡¡ Instala y olvidate de estar pendientes de actualizaciones, el script lo hace por ti!!

El codigo esta diseñado no solo para la instalacion de listas canales y picones para enigma2, ademas te permite interactuar con el mismo para una gestion personalizada de lo que deseas realizar, las acciones que realiza:

-->Instala listas canales enigma2 opcional seleccionable (astra, astra-hotbird, astra-hispasat, astra-hotbird-hispasat, Astra comunitarias)

-->Instala picones de la plataforma movistar seleccionable(picon trasnparente original, picon transparente color , picon reflejo)

-->En caso que tengamos una lista previa con canales IPTV o tdt te los conserva durante la intalacion.

-->Te permite seleccinar que favoritos de nuetra lista no deseas instalar.

-->Te permite seleccionar que favorito personal que tengamos deseas converservar.

Si deseas obtener ayudas asi como prestarlas sobre este desarrollo, asi como con enigma2 en general, tenemos  [grupo de Telegram](https://t.me/joinchat/R_MzlCWf4Kahgb5Gp) . ¡Únete a nosotros!

Si deseas estar a la ultima sobre novedades desarrolladas por jungle team [canal de Telegram noticias](https://t.me/+myB-5lmtSZ1hZDlk) .

## [](jungleteam#instalando)Instalando

--> Puede instalar o actualizar `junglescript` simplemente añadiendo los repositorios jungle-team y luego realizando instalacion:

```{code-block} bash
wget http://tropical.jungle-team.online/script/jungle-feed.conf -P /etc/opkg/
```
```{code-block} bash
opkg update
```
```{code-block} bash
opkg install enigma2-plugin-extensions-junglescript
```
--> Si lo deseas tambien puedes descargarte el paquete ipk desde [Lanzamientos](https://github.com/jungla-team/enigma2_pre_start/tree/master/ipk), una vez descargado, introducirlo en el directorio `tmp`del receptor y ejecutar su instalacion:

## Ejecucion y Funcionamiento

`junglescript` tras su instalacion te crea en el receptor dos archivos:

* `/usr/bin/enigma2_pre_start.sh` que es el script shell, es decir el ejecutable.

* `/usr/bin/enigma2_pre_start.conf` que es el archivo de configuracion donde personalizamos nuestra instalacion.

```{code-block} Importante
Por defecto, esta deshabilitado la instalacion de listas de canales y picones, su activacion opcional asi como los parametros de las demas funciones las editaremos, segun nuestras necesidades.
```

Para configurar la instalacion como hemos comentado se realiza en el archivo `/usr/bin/enigma2_pre_start.conf` y tenemos los siguientes parametros de configuracion e instalacion:

```{code-block} json
LISTA=
LISTACANALES=
FECHA_LISTACANALES=
PICONS=
TIPOPICON=
FECHA_PICONS=
BOUQUETS_NO_DESCARGAR=
BOUQUETS_NO_ACTUALIZAR=
```

`LISTA=` Parametros 0 (no instala lista canales) 1 (instala lista canales)

`LISTACANALES=` Parametro para el tipo lista a instalar, opciones (astra, astra-comunitaria, astra-hotbird, astra-hispasat, astra-hotbird-hispasat)

`FECHA_LISTACANALES=` Parametro que el script introduce automaticamente tras su ejecucion que indica la fecha de la lista canales instalada, si borramos la fecha forzaremos la instalacion de nuevo)

`PICONS=` Parametros 0 (no instala picones) 1 (instala picones)

`TIPOPICON=` Parametros para el tipo de picon a instalar, opciones (movistar-original, movistar-lunar, movistar-color, movistar-color-3d)

`FECHA_PICONS=` Parametro que el script introduce automaticamente tras su ejecucion que indica la fecha de los picones instalados, si borramos la fecha forzaremos la instalacion de nuevo)

`BOUQUETS_NO_DESCARGAR=` Parametros que te permite introducir favoritos de la lista canales que se va a instalar y no deseas que se instalen, ejemplo puedes acceder al source de nuestras listas https://github.com/jungla-team/Canales-enigma2, donde veras que los nombres de los favoritos son userbouquet.austriasat.tv..... simplemente introduce en este ejemplo austriasat, por lo tanto BOUQUETS_NO_DESCARGAR=austriasat en el caso que deseemos introducir mas de un favorito los separamos con , sin espaciones BOUQUETS_NO_DESCARGAR=austriasat,manolillasat,xxxxx

`BOUQUETS_NO_ACTUALIZAR=` Parametros que te permite introducir favoritos que tenganamos en nuestro receptor que no deseas que se borren o actualicen(debido  a que es un favorito personal que tenemos), ejemplo accedes al directorio del deco /etc/enigma2, donde veras que los nombres de los favoritos son userbouquet.austriasat.tv..... simplemente introduce en este ejemplo austriasat, por lo tanto BOUQUETS_NO_ACTUALIZAR=austriasat en el caso que deseemos introducir mas de un favorito los separamos con , sin espaciones BOUQUETS_NO_ACTUALIZAR=austriasat,manolillasat,xxxxx

Una vez realizada la configuracion en cada reinicio Gui del receptor el script comprobara por la fecha de actualizacion si existe una version de listas canales o picones mas actualizados a los que tenemos instalados, y en ese caso se realizara la istalacion de los mismos, creando log de la intalacion en ^/var/log/enigma2_pre_start.log


## Obteniendo ayuda

Si los recursos mencionados anteriormente no responden a sus preguntas o dudas,  o te ha resultado muy complicado, tienes varias formas de obtener ayuda.

1.  Tenemos una comunidad donde se intenta que se ayudan unos a otros en nuestro [grupo de Telegram](https://t.me/joinchat/R_MzlCWf4Kahgb5G) . ¡Únete a nosotros! Hacer una pregunta aquí suele ser la forma más rápida de obtener respuesta y poder hablar directamente con los desarrolladores.
2.  Tambien puedes leer con detenimiento la [Guia avanzada de Junglescript](https://jungle-team.com/junglescript-guia-usuario-rev-2-0/) .

## contribuir

JungleScript esta desarrollado bajo codigo abierto, por lo que las contribuciones de todos los tamaños son bienvenidas para mejorar o ampliar las posibilidades de junglebot. También puede ayudar [informando errores o solicitudes de funciones a traves del grupo telegram](https://t.me/joinchat/R_MzlCWf4Kahgb5G) .

## [](jungleteam#donating)donando

De vez en cuando nos preguntan si aceptamos donaciones para apoyar el desarrollo. Si bien, mantener `junglescript`  es nuestro hobby y  pasatiempo, si tenemos un coste de mantenimiento de servidor de repositorios asi como [del blog enigma2](https://jungle-team.com/), por lo que si deseas colaborar en su mantenimiento sirvase de realizar [Donacion](https://paypal.me/jungleteam)

## [](jungleteam#license)Licencia

Puede copiar, distribuir y modificar el software siempre que las modificaciones se describan y se licencien de forma gratuita bajo [LGPL-3](https://www.gnu.org/licenses/lgpl-3.0.html) . Los trabajos derivados (incluidas las modificaciones o cualquier cosa vinculada estáticamente a la biblioteca) solo se pueden redistribuir bajo LGPL-3.

