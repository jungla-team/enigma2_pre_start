#!/bin/bash
# Provides: jungle-team
# Description: Script para actualizaciones de junglebot, de canales y de picons del equipo jungle-team
# Version: 1.0
# Date: 02/11/2019

crear_dir_tmp() {
	if [ ! -d $DIR_TMP/$CARPETA ] && [ ! $ZIP ];
	then
		mkdir -p $DIR_TMP/$CARPETA
	fi
}

descomprimir_zip() {
	if [ -f $DIR_TMP/$ZIP ];
	then
		if [ -d $DIR_TMP/$CARPETA-master ];
		then
			echo "existe: $DIR_TMP/$CARPETA-master"
			rm -rf $DIR_TMP/$CARPETA-master
		fi
		unzip -d $DIR_TMP $DIR_TMP/$ZIP
	fi
}

renombrar_carpeta() {
	if [ -d $DIR_TMP/$CARPETA-master ];
	then
		mv $DIR_TMP/$CARPETA-master $DIR_TMP/$CARPETA
	fi	  
}

diferencias_fichero() {
	if [ ! -d  $DESTINO ];
	then
		echo "No existe ${DESTINO} en el deco"
	else
		if diff -q $DIR_TMP/$CARPETA/$FICHERO $DESTINO/$FICHERO; 
		then
			CAMBIOS=0
			echo "No hay cambios en el fichero ${FICHERO}"
		else
			CAMBIOS=1
			echo "Hay cambios en el fichero ${FICHERO}"
		fi 
	fi	  
}

instalar_rsync(){
	if [ ! -f /usr/bin/rsync ];
	then
		echo "Instalando rsync..."
		paquete=`opkg list | grep rsync | grep tool | awk '{ print $1 }'`
		opkg install $paquete
	fi
}

actualizar_fichero() {
	if [ "$CAMBIOS" -eq 1 ]
	then
		matar_procesos
		cp $DIR_TMP/$CARPETA/$FICHERO $DESTINO/$FICHERO
		chmod +x $DESTINO/$FICHERO
		reinicia_proceso
		MENSAJE="Actualizacion automatica realizada sobre el bot de jungla-team"
		enviar_telegram $MENSAJE
	fi
}

matar_procesos() {
	PROCESO=`ps -ef | grep ${DAEMON} | grep -v grep | wc -l`
	if [ "$PROCESO" -gt 0 ]
	then
		procesos=`ps -ef | grep ${DAEMON} | grep -v grep | awk '{ print $2 }'`
		for i in $procesos;
		do
			kill -9 $i
		done
	fi
}

reinicia_proceso() {
	if [ "$CAMBIOS" -eq 1 ]
	then
		echo "Reiniciando proceso..."
		matar_procesos
		$DAEMON &
	fi
}

enviar_telegram(){
	PARAM=parametros.py
	DESTINO=/usr/bin/junglebot
	TOKEN=$(cat ${DESTINO}/parametros.py | grep BOT_TOKEN | cut -d'"' -f2 | tr -d '[[:space:]]')
	ID=$(cat /usr/bin/junglebot/parametros.py | grep CHAT_ID | cut -d'=' -f2 | cut -d'#' -f1 | tr -d '[[:space:]]')
	URL="https://api.telegram.org/bot$TOKEN/sendMessage"
	MSJ=$MENSAJE
	curl -s -X POST $URL -d chat_id=$ID -d text="$MSJ"
}

borrado_canales() {
	DESTINO=/etc/enigma2
	ls *.tv *.radio lamedb blacklist whitelist satellites.xml | grep -v favourites | xargs rm
}

diferencias_canales() {
	DESTINO=/etc/enigma2
	LOG_RSYNC_CANALES=rsync_canales.log
	if [ ! -f $DESTINO/streamTDT.tv ]; 
	then
		borrado_canales
		EXCLUDE_FILES=$(echo -e "README.md\nLICENSE\nstreamTDT.tv\nsatellites.xml" > $DIR_TMP/excludes.txt)
		rsync -aiv $DIR_TMP/$CARPETA/* $DESTINO --exclude-from=$DIR_TMP/excludes.txt --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
	else
		borrado_canales
		EXCLUDE_FILES=$(echo -e "README.md\nLICENSE\nsatellites.xml" > $DIR_TMP/excludes.txt)
		rsync -aiv $DIR_TMP/$CARPETA/* $DESTINO --exclude-from=$DIR_TMP/excludes.txt --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
		###gestionar tema lamedb
	fi
	FICH_SAT=satellites.xml
	RUTA_SAT=/etc/tuxbox
	rsync -aiv $DIR_TMP/$CARPETA/$FICH_SAT $RUTA_SAT/$FICH_SAT --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
	CAMBIOS_RSYNC=$(grep -i "+++++++++" $DIR_TMP/$LOG_RSYNC_CANALES)
	if [ ! -z "${CAMBIOS_RSYNC}" ];
	then
		wget -qO - http://127.0.0.1/web/servicelistreload?mode=0
		MENSAJE="Actualizacion automatica realizada sobre los canales ${CARPETA}"
		enviar_telegram $MENSAJE
	else
		echo "CAMBIOS_RSYNC esta vacía"
	fi
}

buscar_picons() {
	RUTA_PICONS=/media/hdd/picon
	HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
	if [ "$HAY_PICONS" -gt 0 ];
	then
		echo "Existe ruta: ${RUTA_PICONS}"
	else
		RUTA_PICONS=/media/usb/picon
		HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
		if [ "$HAY_PICONS" -gt 0 ];
		then
			echo "Existe ruta: ${RUTA_PICONS}"
		else
			RUTA_PICONS=/media/mmc/picon
			HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
			if [ "$HAY_PICONS" -gt 0 ];
			then
				echo "Existe ruta: ${RUTA_PICONS}"
			else
				RUTA_PICONS=/usr/share/enigma2/picon
				HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
				if [ "$HAY_PICONS" -gt 0 ];
				then
					echo "Existe ruta: ${RUTA_PICONS}"
				else
					RUTA_PICONS=""
					echo "No existe ninguna ruta"
				fi
			fi
		fi
	fi
}

diferencias_picons() {
	LOG_RSYNC_PICONS=rsync_picons.log
	buscar_picons
	TIPO_PICON=movistar-original
	rsync -aiv $DIR_TMP/$CARPETA/$TIPO_PICON/* $RUTA_PICONS --log-file=$DIR_TMP/$LOG_RSYNC_PICONS
    CAMBIOS_RSYNC=$(grep -i "+++++++++" $DIR_TMP/$LOG_RSYNC_PICONS)
	if [ ! -z "${CAMBIOS_RSYNC}" ];
	then
		MENSAJE="Actualizacion automatica realizada sobre los picons ${RUTA_PICONS}"
		enviar_telegram $MENSAJE
	else
		echo "CAMBIOS_RSYNC esta vacía"
	fi
}

wget_github_zip() {
	if [[ $1 =~ ^-+h(elp)?$ ]] ; then
		printf "%s\n" "Downloads a github snapshot of a master branch.\nSupports input URLs of the forms */repo_name, *.git, and */master.zip"
		return
	fi
	if [[ ${1} =~ /archive/master.zip$ ]] ; then
		download=${1}
		out_file=${1/\/archive\/master.zip}
		out_file=${out_file##*/}.zip
	elif [[ ${1} =~ .git$ ]] ; then
		out_file=${1/%.git}
		download=${out_file}/archive/master.zip
		out_file=${out_file##*/}.zip
	else
		out_file=${1/%\/} # remove trailing '/'
		download=${out_file}/archive/master.zip
		out_file=${out_file##*/}.zip
	fi
	wget -c ${download} -O ${out_file}
	mv ${out_file} $DIR_TMP
}

wget_github_file() {
	wget $URL -O $DIR_TMP/$CARPETA/$FICHERO
}

limpiar_dir_tmp() {
	if [ -d $DIR_TMP ];
	then
		rm -rf "${DIR_TMP}/junglebot" 
		rm -rf "${DIR_TMP}/MovistarPlus-Astra" 
		rm -rf "${DIR_TMP}/picon-movistar"
		rm -f "${DIR_TMP}/MovistarPlus-Astra.zip"
		rm -f "${DIR_TMP}/picon-movistar.zip"
	fi
}

diff_github_actualizacion(){
	actualizacion=$(cat ${FICHERO_ACTUALIZACION} 2>/dev/null)
	instalada=$(curl -s ${URL_ACTUALIZACION} 2>/dev/null)

	if [ "$actualizacion" != "$instalada" ]; then
		ACTUALIZACION="YES"
	else
		ACTUALIZACION="NO"
	fi
}

#### Para actualizar junglebot #####

URL=https://raw.githubusercontent.com/jungla-team/junglebot/master/bot.py
CARPETA=junglebot
DESTINO=/usr/bin/$CARPETA
FICHERO=bot.py
DAEMON=$DESTINO/$FICHERO

if [ -f /usr/bin/$CARPETA/$FICHERO ];
then
	crear_dir_tmp
	wget_github_file
	diferencias_fichero
	actualizar_fichero
fi

#### Para actualizar lista de canales #####

DESTINO=/etc/enigma2
URL=https://github.com/jungla-team/MovistarPlus-Astra/archive/master.zip
CARPETA=MovistarPlus-Astra
DIR_TMP=/tmp
ZIP=$CARPETA.zip

if [ -f $DESTINO/actualizacion ];
then
    URL_ACTUALIZACION=https://raw.githubusercontent.com/jungla-team/MovistarPlus-Astra/master/actualizacion
	FICHERO_ACTUALIZACION=$DESTINO/actualizacion
	diff_github_actualizacion
	if [ "${ACTUALIZACION}" == "YES" ];
	then
		crear_dir_tmp
		wget_github_zip $URL
		descomprimir_zip
		renombrar_carpeta
		instalar_rsync
		diferencias_canales
	else
		echo "No hay cambios en canales"
	fi
else
	echo "No existe fichero de actualizacion de canales, asi que fuerzo la actualizacion de canales"
	crear_dir_tmp
	wget_github_zip $URL
	descomprimir_zip
	renombrar_carpeta
	instalar_rsync
	diferencias_canales
fi

#### Para actualizar picons #####

URL=https://github.com/jungla-team/picon-movistar/archive/master.zip
CARPETA=picon-movistar
DIR_TMP=/tmp
ZIP=$CARPETA.zip
			
buscar_picons
if [ ! -z "${RUTA_PICONS}" ];
then
	if [ -f "${RUTA_PICONS}/actualizacion" ];
	then
		URL_ACTUALIZACION=https://raw.githubusercontent.com/jungla-team/picon-movistar/master/movistar-original/actualizacion
		FICHERO_ACTUALIZACION=$RUTA_PICONS/actualizacion
		diff_github_actualizacion
		if [ "${ACTUALIZACION}" == "YES" ];
		then	
			crear_dir_tmp
			wget_github_zip $URL
			descomprimir_zip
			renombrar_carpeta
			diferencias_picons
		else
			echo "No hay cambios en picons"
		fi
	else
		echo "No existe fichero de actualizacion de picons, asi que fuerzo la actualizacion de picons"
		crear_dir_tmp
		wget_github_zip $URL
		descomprimir_zip
		renombrar_carpeta
		diferencias_picons
	fi
else
	echo "No existe ninguna ruta con picons, asi que no actualizo"
fi

#### Limpieza en DIR_TMP

if [ ! -z "${DIR_TMP}" ];
then
	echo "Limpiando ${DIR_TMP}"
	limpiar_dir_tmp
fi
