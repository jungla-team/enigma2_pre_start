#!/bin/bash
# Provides: jungle-team
# Description: JungleScript para actualizaciones de lista de canales y de picons del equipo jungle-team
# Version: 5.6
# Date: 01/03/2021 

VERSION=5.6
LOGFILE=/var/log/enigma2_pre_start.log
URL_TROPICAL=http://tropical.jungle-team.online
exec 1> $LOGFILE 2>&1
set -x

crear_dir_tmp() {
	if [ ! -d $DIR_TMP/$CARPETA ] && [ ! $ZIP ];
	then
		echo "creando carpeta $DIR_TMP/$CARPETA"
		mkdir -p $DIR_TMP/$CARPETA
	else
		echo "no crea la carpeta temporal $DIR_TMP/$CARPETA"
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

parar_proceso() {
    DEMONIO=$1
	PROCESO=`ps -ef | grep ${DEMONIO} | grep -v grep | wc -l`
	if [ "$PROCESO" -gt 0 ]
	then
		procesos=`ps -ef | grep ${DEMONIO} | grep -v grep | awk '{ print $2 }'`
		for i in $procesos;
		do
			kill -9 $i
		done
	fi
}

arranca_proceso() {
	DEMONIO=$1
	PIDFILE_NAME=$2
	PIDFILE="/var/run/${PIDFILE_NAME}.pid"
	PROCESO=`ps -ef | grep ${DEMONIO} | grep -v grep | wc -l`
	if [ "$PROCESO" -eq 0 ]
	then
		INIT=$(ls /sbin/start-stop-daemon)
		if [ -f $INIT ];
		then
			$INIT -S -b -x $DEMONIO -p $PIDFILE -m
		else
			$DEMONIO
		fi
	else
		echo "Hay procesos levantados $DEMONIO"
	fi
}

enviar_telegram(){
	PARAM=parametros.py
	DEST=/usr/bin/junglebot
	BOT_ACTIVO=$(ps -A | grep bot.py | wc -l)
	if [ "$BOT_ACTIVO" -gt 0 ];
	then
		TOKEN=$(cat ${DEST}/parametros.py | grep BOT_TOKEN | cut -d'=' -f2 | tr -d '[[:space:]]')
		ID=$(cat ${DEST}/parametros.py | grep CHAT_ID | cut -d'=' -f2 | cut -d'#' -f1 | tr -d '[[:space:]]')
		URL="https://api.telegram.org/bot$TOKEN/sendMessage"
		MSJ=$1
		curl -s -X POST $URL -d chat_id=$ID -d text="$MSJ"
	else
		echo "No puedo enviar mensajes de telegram, ya que el bot no esta activo"
	fi
}

enviar_mensaje_pantalla(){
    MENSA=$1
	MSJ=$(echo ${MENSA// /+})
	URL="http://127.0.0.1/web/message?text=${MSJ}&type=2"
	wget -qO - $URL
}

borrado_canales() {
	DESTINO=/etc/enigma2
	HAY_FAV_TDT=$(grep -il ee0000 ${DESTINO}/*.tv | wc -l)
	HAY_FAV_IPTV=$(grep -il http ${DESTINO}/*.tv | wc -l)
	EXCLUDE_FAV=exclude_fav.txt
	if [ -f ${DESTINO}/save_bouquets ];
	then
		HAY_PARA_SALVAR=$(cat ${DESTINO}/save_bouquets | wc -l)
	else
		HAY_PARA_SALVAR=0
	fi
	if [ "$HAY_FAV_TDT" -gt 0 ] || [ "$HAY_FAV_IPTV" -gt 0 ] || [ "$HAY_PARA_SALVAR" -gt 0 ];
	then
		for i in $(ls ${DESTINO}/*.tv);
		do
			BOUQUET_FILE=$i
			EXCLUIR_FAV_TDT=$(grep -il ee0000 ${BOUQUET_FILE} | wc -l)
			EXCLUIR_FAV_IPTV=$(grep -il http ${BOUQUET_FILE} | wc -l)
			salvar_bouquet $BOUQUET_FILE
			if [ "$EXCLUIR_FAV_TDT" -eq 0 ] && [ "$EXCLUIR_FAV_IPTV" -eq 0 ] && [ "$SALVAR_BOUQUET" -eq 0 ];
			then
				echo "Borro bouquet: $BOUQUET_FILE"
				rm -f $BOUQUET_FILE
			else
				BOUQUET_NAME=$(echo ${BOUQUET_FILE} | cut -d'/' -f4)
				echo "Bouquet excluido: $BOUQUET_NAME"
				echo $BOUQUET_NAME >> $DIR_TMP/$EXCLUDE_FAV
				echo -e $BOUQUET_NAME >> $DIR_TMP/excludes.txt
			fi
			rm -f $CARPETA/$FICHERO
		done
		ls $DESTINO/*.radio $DESTINO/lamedb $DESTINO/blacklist $DESTINO/whitelist $DESTINO/satellites.xml | xargs rm
	else
		ls $DESTINO/*.tv $DESTINO/*.radio $DESTINO/lamedb $DESTINO/blacklist $DESTINO/whitelist $DESTINO/satellites.xml | xargs rm
	fi
}

salvar_bouquet(){
	BOUQUET=$1
	DESTINO=/etc/enigma2
	SALVAR_BOUQUET=0
	if [ -f ${DESTINO}/save_bouquets ];
	then
		HAY_PARA_SALVAR=$(cat ${DESTINO}/save_bouquets | wc -l)
		if [ "$HAY_PARA_SALVAR" -gt 0 ];
		then
			NUM_PUNTOS=$(echo ${BOUQUET} | grep -o "\." | wc -l)
			BOUQUET_NAME_SINPUNTOS=$(basename ${BOUQUET} | cut -d '.' -f${NUM_PUNTOS})
			SALVAR_BOUQUET=$(grep ${BOUQUET_NAME_SINPUNTOS} ${DESTINO}/save_bouquets | wc -l)
		fi
	fi
}

recargar_lista_canales() {
	wget -qO - http://127.0.0.1/web/servicelistreload?mode=0
}

diferencias_canales() {
	DESTINO=/etc/enigma2
	LOG_RSYNC_CANALES=rsync_canales.log
	echo -e "README.md\nLICENSE\nsatellites.xml" > $DIR_TMP/excludes.txt
	borrado_canales
	if [ -f $DESTINO/fav_bouquets ];
	then
		for i in $(cat $DESTINO/fav_bouquets);
		do
			ls $DIR_TMP/$CARPETA/*.tv | grep $i | cut -d'/' -f7 >> $DIR_TMP/excludes.txt
			sed -i "/$i/d" $DIR_TMP/$CARPETA/bouquets.tv
		done
	fi
	cat $DIR_TMP/excludes.txt
	rsync -aiv $DIR_TMP/$CARPETA/* $DESTINO --exclude-from=$DIR_TMP/excludes.txt --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
	FICH_SAT=satellites.xml
	RUTA_SAT=/etc/tuxbox
	LINEA=3
	rsync -aiv $DIR_TMP/$CARPETA/$FICH_SAT $RUTA_SAT/$FICH_SAT --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
	if [ -f $DIR_TMP/$EXCLUDE_FAV ];
	then
		for i in $(cat ${DIR_TMP}/${EXCLUDE_FAV});
		do
			EXISTE_FAV=$(grep -i "${i}" $DESTINO/bouquets.tv | wc -l)
			if [ "$EXISTE_FAV" -eq 0 ];
			then
				if [ "${i}" != "bouquets.tv" ];
				then
					sed -i ${LINEA}'a\#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "'${i}'" ORDER BY bouquet' $DESTINO/bouquets.tv
					let LINEA=LINEA+1
				fi
			else
					echo "Existe favorito ${i} ya previamente en bouquets.tv"
			fi
		done
	fi
	CAMBIOS_RSYNC=$(grep -i "+++++++++" $DIR_TMP/$LOG_RSYNC_CANALES)
	if [ ! -z "${CAMBIOS_RSYNC}" ];
	then
		recargar_lista_canales
		MENSAJE="Actualizacion automatica realizada sobre los canales ${LISTACANALES}"
		enviar_telegram "${MENSAJE}"
		enviar_mensaje_pantalla "${MENSAJE}"
		echo $MENSAJE
	else
		echo "CAMBIOS_RSYNC esta vacía"
	fi
	sed -i "/bouquets.tv/d" $DESTINO/bouquets.tv
	echo "Aplicando dos2unix al fichero de bouquets.tv por si acaso"
	/usr/bin/dos2unix $DESTINO/bouquets.tv
}

buscar_picons() {
	RUTA_PICONS=/media/hdd/picon
	HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
	HDD_MONTADO=$(mount | grep hdd | wc -l)
	if [ "$HAY_PICONS" -gt 0 ] && [ "$HDD_MONTADO" -gt 0 ];
	then
		echo "Existe ruta: ${RUTA_PICONS}"
	else
		RUTA_PICONS=/media/usb/picon
		HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
		USB_MONTADO=$(mount | grep usb | wc -l)
		if [ "$HAY_PICONS" -gt 0 ] && [ "$USB_MONTADO" -gt 0 ];
		then
			echo "Existe ruta: ${RUTA_PICONS}"
		else
			RUTA_PICONS=/media/mmc/picon
			HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
			MMC_MONTADO=$(mount | grep mmc | wc -l)
			if [ "$HAY_PICONS" -gt 0 ] && [ "$MMC_MONTADO" -gt 0 ];
			then
				echo "Existe ruta: ${RUTA_PICONS}"
			else
				RUTA_PICONS=/usr/share/enigma2/picon
				HAY_PICONS=$(ls -ld $RUTA_PICONS | wc -l)
				if [ "$HAY_PICONS" -gt 0 ];
				then
					echo "Existe ruta: ${RUTA_PICONS}"
				else
					echo "No existe ninguna ruta"
					RUTA=/media/hdd
					HDD_MONTADO=$(mount | grep hdd | wc -l)
					if [ -d "$RUTA" ] && [ "$HDD_MONTADO" -gt 0 ];
					then
						RUTA_PICONS=${RUTA}/picon
						mkdir -p ${RUTA_PICONS}
						echo "Creada la ruta: ${RUTA_PICONS}"
					else
						RUTA=/media/usb
						USB_MONTADO=$(mount | grep usb | wc -l)
						if [ -d "$RUTA" ] && [ "$USB_MONTADO" -gt 0 ];
						then
							RUTA_PICONS=${RUTA}/picon
							mkdir -p ${RUTA_PICONS}
							echo "Creada la ruta: ${RUTA_PICONS}"
						else
							RUTA=/media/mmc
							MMC_MONTADO=$(mount | grep mmc | wc -l)
							if [ -d "$RUTA" ] && [ "$MMC_MONTADO" -gt 0 ];
							then
								RUTA_PICONS=${RUTA}/picon
								mkdir -p ${RUTA_PICONS}
								echo "Creada la ruta: ${RUTA_PICONS}"
							else
								RUTA=/usr/share/enigma2
								if [ -d "$RUTA" ];
								then
									RUTA_PICONS=${RUTA}/picon
									mkdir -p ${RUTA_PICONS}
									echo "Creada la ruta: ${RUTA_PICONS}"
								fi
							fi
						fi
					fi
				fi
			fi
		fi
	fi
}

diferencias_picons() {
	LOG_RSYNC_PICONS=rsync_picons.log
	buscar_picons
	rsync -aiv $DIR_TMP/$CARPETA/* $RUTA_PICONS --log-file=$DIR_TMP/$LOG_RSYNC_PICONS
    CAMBIOS_RSYNC_1=$(grep -i "f+++++++++" $DIR_TMP/$LOG_RSYNC_PICONS | wc -l)
	CAMBIOS_RSYNC_2=$(grep -i "f.st......" $DIR_TMP/$LOG_RSYNC_PICONS | wc -l)
	if [ "${CAMBIOS_RSYNC_1}" -gt 0 ] || [ "${CAMBIOS_RSYNC_2}" -gt 0 ];
	then
		MENSAJE="Actualizacion automatica realizada sobre los picons ${RUTA_PICONS}"
		enviar_telegram "${MENSAJE}"
		echo $MENSAJE
	else
		echo "No hay cambios en los picons"
	fi
}

redimensionamiento_picons() {
	if [ -f /etc/bhmachine ];
	then
		echo "Redimendionsando picons en sistema Blackhole"
		opkg update
		opkg install python-imaging
		URL=$URL_TROPICAL/utilidades/resizepicon.py
		CARPETA=/usr/bin/
		FICHERO=resizepicon.py
		curl $URL -o $CARPETA/$FICHERO
		if [ $? -eq 0 ];
		then
			python $CARPETA/$FICHERO $RUTA_PICONS
			MENSAJE="Se han redimensionado los picons en sistema Blackhole"
			enviar_telegram "${MENSAJE}"
		else
			echo "Errores al descargar $URL"
			exit 1
		fi
    fi
}

wget_zip() {
	download=${1}
	curl ${download} -o $DIR_TMP/$ZIP
	if [ $? -ne 0 ];
	then
		echo "Errores al descargar $download"
		exit 1
	fi
}

wget_file() {
	curl $URL -o $DIR_TMP/$CARPETA/$FICHERO
	if [ $? -eq 0 ];
	then
		chmod +x $DIR_TMP/$CARPETA/$FICHERO
	else
		echo "Errores al descargar $URL"
		exit 1
	fi
}

limpiar_dir_tmp() {
	if [ -d $DIR_TMP ];
	then
		borrar_directorio "${DIR_TMP}/junglebot" 
		borrar_directorio "${DIR_TMP}/Canales-enigma2-main"
		borrar_directorio "${DIR_TMP}/Picon-enigma2-Movistar-main"
		borrar_fichero "${DIR_TMP}/Jungle-Astra-19.2.zip.zip"
		borrar_fichero "${DIR_TMP}/Jungle-Astra19.2-hotbird13.zip"
		borrar_fichero "${DIR_TMP}/Jungle-Astra-19.2-comunitarias.zip"
		borrar_fichero "${DIR_TMP}/movistar-*.zip"
		borrar_fichero "${DIR_TMP}/exclude_fav.txt"
		borrar_fichero "${DIR_TMP}/excludes.txt"
		borrar_fichero "${DIR_TMP}/enigma2_pre_start.conf.tmp"
	fi
}

borrar_fichero() {
	FICH=$1
	if [ -f $FICH ];
	then
		rm -f $FICH
	fi
}

borrar_directorio() {
	DIR=$1
	if [ -d $DIR ];
	then
		rm -rf $DIR
	fi
}

diff_actualizacion(){
	actualizacion=$(cat ${FICHERO_ACTUALIZACION} 2>/dev/null)
	instalada=$(curl -k -s ${URL_ACTUALIZACION} 2>/dev/null)

	if [ "$actualizacion" != "$instalada" ]; 
	then
		ACTUALIZACION="YES"
	else
		ACTUALIZACION="NO"
	fi
}

merge_lamedb() {
	DESTINO=/etc/enigma2
	if grep -q "eeee0000:" "$DESTINO/lamedb";
	then
		echo "Tiene TDT"
		((nlinea = 99999))
		while IFS= read -r line; do
			if [[ $line == *"eeee0000:"* ]]; then
				((nlinea = 1))
				if [[ $line == "eeee0000:"* ]]; then
					TIPO=TRANSPONDER
				else
					TIPO=SERVICE
				fi
			else
				((nlinea++))
			fi
			
			if (( nlinea < 4 )); then 
				if [[ $TIPO == "TRANSPONDER" ]]; then
					echo "$line"  >> "$DIR_TMP/$CARPETA/lamedb_tdt_transponders"
				else
					echo "$line"  >> "$DIR_TMP/$CARPETA/lamedb_tdt_services"
				fi
			fi			
		done < "$DESTINO/lamedb"

		while IFS= read -r line; do
			echo "$line"  >> "$DIR_TMP/$CARPETA/lamedb_final"
			if [[ $line == "transponders"* ]]; then
				cat "$DIR_TMP/$CARPETA/lamedb_tdt_transponders" >> "$DIR_TMP/$CARPETA/lamedb_final"
			elif [[ $line == "services"* ]]; then
				cat "$DIR_TMP/$CARPETA/lamedb_tdt_services" >> "$DIR_TMP/$CARPETA/lamedb_final"
			fi
		done < "$DIR_TMP/$CARPETA/lamedb"
		rm "$DIR_TMP/$CARPETA/lamedb_tdt_transponders"
		rm "$DIR_TMP/$CARPETA/lamedb_tdt_services"
		mv -f "$DIR_TMP/$CARPETA/lamedb_final" "$DIR_TMP/$CARPETA/lamedb"
		echo "Ya se ha regenerado lamedb con los canales de TDT anteriores"
	else
		echo "No tiene TDT"
	fi
}

comprobar_espacio(){
	hdd_montado=$(mount | grep hdd | wc -l)
	usb_montado=$(mount | grep usb | wc -l)
	if [ "$hdd_montado" -eq 0 ] && [ "$usb_montado" -eq 0 ];
	then
		umbral=30000
	else
		umbral=15000
	fi
	
    espacio_libre_tmp=$(df -k /tmp | awk '{ print $4 }' | tail -1)
	if [ $espacio_libre_tmp -gt $umbral ]; 
	then
		ESPACIO_TMP="OK";
		echo "Hay espacio libre en /tmp ==> ${espacio_libre_tmp}"
	else 
		ESPACIO_TMP="NOK";
        echo "No hay espacio libre en /tmp ==> ${espacio_libre_tmp}"		
	fi
	
    espacio_libre=$(df -k ${RUTA_PICONS} | awk '{ print $4 }' | tail -1)
	if [ $espacio_libre -gt $umbral ]; 
	then
		ESPACIO_PICONS="OK";
		echo "Hay espacio libre en ${RUTA_PICONS} ==> ${espacio_libre}"
	else 
		ESPACIO_PICONS="NOK"; 
		echo "No hay espacio libre en ${RUTA_PICONS} ==> ${espacio_libre}"
	fi	
}

cargar_variables_conf(){
	DIR_USR=/usr/bin
	FICH_CONFIG=$DIR_USR/enigma2_pre_start.conf
	FICH_CONFIG_TMP=$DIR_TMP/enigma2_pre_start.conf.tmp
	if [ ! -f $FICH_CONFIG ];
	then
		echo -e "LISTACANALES=astra\nPICONS=0\nTIPOPICON=movistar-original\nTDTCHANNELS=0\nPLUTOTV=0" > $FICH_CONFIG
	else
		grep -v -e '^[[:space:]]*$' $FICH_CONFIG > $FICH_CONFIG_TMP
		cp $FICH_CONFIG_TMP $FICH_CONFIG
		num_lineas_fich_config=$(cat ${FICH_CONFIG} | wc -l)
		if [ "$num_lineas_fich_config" -lt 5 ];
		then
		    lista_canales_conf=$(grep -i LISTACANALES ${FICH_CONFIG} | cut -d'=' -f2)
			if [ ! "$lista_canales_conf" ];
			then
				lista_canales_conf=astra
			fi
			picons_conf=$(grep -i PICONS ${FICH_CONFIG} | cut -d'=' -f2)
			if [ ! "$picons_conf" ];
			then
				picons_conf=0
			fi
			tipo_picon_conf=$(grep -i TIPOPICON ${FICH_CONFIG} | cut -d'=' -f2)
			if [ ! "$tipo_picon_conf" ];
			then
				tipo_picon_conf=movistar-original
			fi
			tdtchannels_conf=$(grep -i TDTCHANNELS ${FICH_CONFIG} | cut -d'=' -f2)
			if [ ! "$tdtchannels_conf" ];
			then
				tdtchannels_conf=0
			fi
			plutotv_conf=$(grep -i PLUTOTV ${FICH_CONFIG} | cut -d'=' -f2)
			if [ ! "$plutotv_conf" ];
			then
				plutotv_conf=0
			fi
			echo "Recreando fichero de config porque no tenía cinco líneas"
			echo -e "LISTACANALES=${lista_canales_conf}\nPICONS=${picons_conf}\nTIPOPICON=${tipo_picon_conf}\nTDTCHANNELS=${tdtchannels_conf}\nPLUTOTV=${plutotv_conf}" > $FICH_CONFIG
		fi
		echo "Aplicando dos2unix al fichero de config por si acaso"
		/usr/bin/dos2unix $FICH_CONFIG
	fi
	. $FICH_CONFIG
}

actualizar_listacanales(){
	case "$LISTACANALES" in
	'astra')
		URL=$URL_TROPICAL/oasis/lista_canales/Jungle-Astra-19.2.zip
		URL_ACTUALIZACION=$URL_TROPICAL/oasis/lista_canales/astra/etc/enigma2/actualizacion
		CARPETA=Canales-enigma2-main/Jungle-Astra-19.2/etc/enigma2
		ZIP=Jungle-Astra-19.2.zip
		;;
	'astra-hotbird')
		URL=$URL_TROPICAL/oasis/lista_canales/Jungle-Astra19.2-hotbird13.zip
		URL_ACTUALIZACION=$URL_TROPICAL/oasis/lista_canales/astra-hotbird/etc/enigma2/actualizacion
		CARPETA=Canales-enigma2-main/Jungle-Astra19.2-hotbird13/etc/enigma2
		ZIP=Jungle-Astra19.2-hotbird13.zip
		;;
	'astra-comunitaria')
		URL=$URL_TROPICAL/oasis/lista_canales/Jungle-Astra-19.2-comunitarias.zip
		URL_ACTUALIZACION=$URL_TROPICAL/oasis/lista_canales/astra-comunitarias/etc/enigma2/actualizacion
		CARPETA=Canales-enigma2-main/Jungle-Astra-19.2-comunitarias/etc/enigma2
		ZIP=Jungle-Astra-19.2-comunitarias.zip
		;;
	'astra-hotbird-hispasat')
		URL=$URL_TROPICAL/oasis/lista_canales/Jungle-Astra19.2-Hotbird13-Hispasat30.zip
		URL_ACTUALIZACION=$URL_TROPICAL/oasis/lista_canales/astra-hotbird-hispasat/etc/enigma2/actualizacion
		CARPETA=Canales-enigma2-main/Jungle-Astra19.2-Hotbird13-Hispasat30/etc/enigma2
		ZIP=Jungle-Astra19.2-Hotbird13-Hispasat30.zip
		;;
	'astra-hispasat')
		URL=$URL_TROPICAL/oasis/lista_canales/Jungle-Astra19.2-Hispasat30.zip
		URL_ACTUALIZACION=$URL_TROPICAL/oasis/lista_canales/astra-hispasat/etc/enigma2/actualizacion
		CARPETA=Canales-enigma2-main/Jungle-Astra19.2-Hispasat30/etc/enigma2
		ZIP=Jungle-Astra19.2-Hispasat30.zip
		;;
	'*')
		URL=$URL_TROPICAL/oasis/lista_canales/Jungle-Astra-19.2.zip
		URL_ACTUALIZACION=$URL_TROPICAL/oasis/lista_canales/astra/etc/enigma2/actualizacion
		CARPETA=Canales-enigma2-main/Jungle-Astra-19.2/etc/enigma2
		ZIP=Jungle-Astra-19.2.zip
		;;
	esac

	DESTINO=/etc/enigma2
	DIR_TMP=/tmp

	if [ -f $DESTINO/actualizacion ];
	then
		FICHERO_ACTUALIZACION=$DESTINO/actualizacion
		diff_actualizacion
		if [ "${ACTUALIZACION}" == "YES" ];
		then
			crear_dir_tmp
			wget_zip $URL
			descomprimir_zip
			renombrar_carpeta
			merge_lamedb
			diferencias_canales
			actualizar_tdtchannels
			actualizar_plutotv
		else
			echo "No hay cambios en canales"
		fi
	else
		echo "No existe fichero de actualizacion de canales, asi que fuerzo la actualizacion de canales"
		crear_dir_tmp
		wget_zip $URL
		descomprimir_zip
		renombrar_carpeta
		merge_lamedb
		diferencias_canales
		actualizar_tdtchannels
		actualizar_plutotv
	fi
}

actualizar_picons(){
	if [ "$PICONS" -eq 1 ];
	then
	    case "$TIPOPICON" in
		'movistar-original')
			TIPO_PICON=movistar-original
			URL=$URL_TROPICAL/oasis/picones/jungle_movistar/jungle-picon-Movistar-Transparente.zip
		    URL_ACTUALIZACION=$URL_TROPICAL/oasis/picones/jungle_movistar/trans/picon/actualizacion
			CARPETA="Picon-enigma2-Movistar-main/jungle-picon-Movistar-Transparente/picon"
			;;
		'movistar-lunar')
			TIPO_PICON=movistar-lunar
			URL=$URL_TROPICAL/oasis/picones/jungle_movistar/jungle-picon-movistar-lunar.zip
		    URL_ACTUALIZACION=$URL_TROPICAL/oasis/picones/jungle_movistar/black/picon/actualizacion
			CARPETA="Picon-enigma2-Movistar-main/jungle-picon-Movistar-lunar/picon"
			;;
		'movistar-color')
			TIPO_PICON=movistar-color
			URL=$URL_TROPICAL/oasis/picones/jungle_movistar/jungle-picon-movistar-color.zip
		    URL_ACTUALIZACION=$URL_TROPICAL/oasis/picones/jungle_movistar/color/picon/actualizacion
			CARPETA="Picon-enigma2-Movistar-main/jungle-picon-Movistar-color/picon"
			;;
		'movistar-color-3d')
			TIPO_PICON=movistar-color
			URL=$URL_TROPICAL/oasis/picones/jungle_movistar/jungle-picon-movistar-color-3d.zip
		    URL_ACTUALIZACION=$URL_TROPICAL/oasis/picones/jungle_movistar/color-3d/picon/actualizacion
			CARPETA="Picon-enigma2-Movistar-main/jungle-picon-Movistar-color-3d/picon"
			;;
		'*')
			TIPO_PICON=movistar-original
			URL=$URL_TROPICAL/oasis/picones/jungle_movistar/jungle-picon-Movistar-Transparente.zip
		    URL_ACTUALIZACION=$URL_TROPICAL/oasis/picones/jungle_movistar/trans/picon/actualizacion
			CARPETA="Picon-enigma2-Movistar-main/jungle-picon-Movistar-Transparente/picon"
			;;
		esac
		ZIP="${TIPO_PICON}.zip"
		buscar_picons
		if [ ! -z "${RUTA_PICONS}" ];
		then
			if [ -f "${RUTA_PICONS}/actualizacion" ];
			then
				FICHERO_ACTUALIZACION=$RUTA_PICONS/actualizacion
				diff_actualizacion
				if [ "${ACTUALIZACION}" == "YES" ];
				then
					comprobar_espacio
					if [ "${ESPACIO_TMP}" = "OK" ] && [ "${ESPACIO_PICONS}" = "OK" ];
					then
						crear_dir_tmp
						wget_zip $URL
						descomprimir_zip
						renombrar_carpeta
						diferencias_picons
						redimensionamiento_picons
					else
						echo "No hay espacio libre en /tmp o en en ${RUTA_PICONS} para descargar los picons. Hay que revisar"
					fi
				else
					echo "No hay cambios en picons"
				fi
			else
				echo "No existe fichero de actualizacion de picons, asi que fuerzo la actualizacion de picons"
				comprobar_espacio
				if [ "${ESPACIO_TMP}" = "OK" ] && [ "${ESPACIO_PICONS}" = "OK" ];
				then
					crear_dir_tmp
					wget_zip $URL
					descomprimir_zip
					renombrar_carpeta
					diferencias_picons
					redimensionamiento_picons
				else
					echo "No hay espacio libre en /tmp o en en ${RUTA_PICONS} para descargar los picons. Hay que revisar"
				fi
			fi
		else
			echo "No existe ninguna ruta con picons, asi que no actualizo"
		fi
	else
		echo "Variable PICONS=0, asi que no actualizo los picons"
	fi
}

insertar_feed_jungleteam() {
	feed_jungle_file="/etc/opkg/jungle-feed.conf"
	if [ ! -f ${feed_jungle_file} ];
	then
		wget $URL_TROPICAL/script/jungle-feed.conf -P /etc/opkg/
	fi
}

actualizar_junglescript() {
	echo "Instalando JungleScript..."
	insertar_feed_jungleteam
	junglescript_package="enigma2-plugin-extensions-junglescript"
	hay_junglescript=$(opkg list-installed | grep ${junglescript_package} | wc -l)
	opkg update
	if [ "$hay_junglescript" -gt 0 ];
	then
		hay_upgrade_junglescript=$(opkg list-upgradable | grep junglescript | wc -l)
		if [ "$hay_upgrade_junglescript" -gt 0 ];
		then
			opkg upgrade $junglescript_package
			salida=$?
			if [ "$salida" -eq 0 ];
			then
				MENSAJE="Actualizacion automatica realizada sobre JungleScript"
				enviar_telegram "${MENSAJE}"
			else
				if [ "$salida" -lt 255 ];
				then
					MENSAJE="Problema en la actualizacion automatica realizada sobre JungleScript"
					enviar_telegram "${MENSAJE}"
				fi
			fi
		fi
	else
		opkg remove junglescript
		opkg install $junglescript_package
		salida=$?
		if [ "$salida" -eq 0 ];
		then
			MENSAJE="Actualizacion automatica realizada sobre JungleScript"
			enviar_telegram "${MENSAJE}"
		else
			if [ "$salida" -lt 255 ];
			then
					MENSAJE="Problema en la actualizacion automatica realizada sobre JungleScript"
					enviar_telegram "${MENSAJE}"
			fi
		fi
	fi
}

actualizar_tdtchannels() {
	DEST_TDTCHANNELS=/etc/enigma2
	FICHERO_TDTCHANNELS="userbouquet.tdtchannels.tv"
	if [ "$TDTCHANNELS" -eq 1 ];
	then
		URL_TDTCHANNELS="https://www.tdtchannels.com/lists/userbouquet.tdtchannels.tv"
		curl $URL_TDTCHANNELS -o $DEST_TDTCHANNELS/$FICHERO_TDTCHANNELS
		EXISTE_TDTCHANNELS=$(grep -i "${FICHERO_TDTCHANNELS}" ${DEST_TDTCHANNELS}/bouquets.tv | wc -l)
		if [ "$EXISTE_TDTCHANNELS" -eq 0 ];
		then
			sed -i ${LINEA}'a\#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "'${FICHERO_TDTCHANNELS}'" ORDER BY bouquet' $DESTINO/bouquets.tv
			let LINEA=LINEA+1
		else
			echo "Existe favorito ${FICHERO_TDTCHANNELS} ya previamente en bouquets.tv"
		fi
	else
		if [ -f "$DEST_TDTCHANNELS/$FICHERO_TDTCHANNELS" ];
		then
			rm -f $DEST_TDTCHANNELS/$FICHERO_TDTCHANNELS
			sed -i '/tdtchannels/ d' $DEST_TDTCHANNELS/bouquets.tv
		fi
	fi
}

actualizar_plutotv() {
	DEST_PLUTOTV=/etc/enigma2
	FICHERO_PLUTOTV="userbouquet.plutotv.tv"
	if [ "$PLUTOTV" -eq 1 ];
	then
		URL_PLUTOTV="$URL_TROPICAL/plutoTV/userbouquet.plutotv.tv"
		curl $URL_PLUTOTV -o $DEST_PLUTOTV/$FICHERO_PLUTOTV
		EXISTE_PLUTOTV=$(grep -i "${FICHERO_PLUTOTV}" ${DEST_PLUTOTV}/bouquets.tv | wc -l)
		if [ "$EXISTE_PLUTOTV" -eq 0 ];
		then
			sed -i ${LINEA}'a\#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "'${FICHERO_PLUTOTV}'" ORDER BY bouquet' $DESTINO/bouquets.tv
			let LINEA=LINEA+1
		else
			echo "Existe favorito ${FICHERO_PLUTOTV} ya previamente en bouquets.tv"
		fi
	else
		if [ -f "$DEST_PLUTOTV/$FICHERO_PLUTOTV" ];
		then
			rm -f $DEST_PLUTOTV/$FICHERO_PLUTOTV
			sed -i '/plutotv/ d' $DEST_PLUTOTV/bouquets.tv
		fi
	fi
}

#### Incluir en el log la versión de JungleScript que está usando
echo "Versión JungleScript: ${VERSION}"

#### Limpieza en DIR_TMP + rsync_canales.log + rsync_picons.log

DIR_TMP=/tmp

if [ ! -z "${DIR_TMP}" ];
then
	echo "Limpiando ${DIR_TMP}"
	limpiar_dir_tmp
	borrar_fichero "${DIR_TMP}/rsync_canales.log"
	borrar_fichero "${DIR_TMP}/rsync_picons.log"
fi

#### Cargar variables del fichero de configuracion #####

cargar_variables_conf

#### Para actualizar lista de canales #####

actualizar_listacanales

#### Para actualizar picons #####

actualizar_picons

#### Actualizacion de JungleScript

actualizar_junglescript

#### Limpieza en DIR_TMP

if [ ! -z "${DIR_TMP}" ];
then
	echo "Limpiando ${DIR_TMP}"
	limpiar_dir_tmp
fi

echo "Saliendo..."
exit 0