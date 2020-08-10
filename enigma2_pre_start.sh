#!/bin/bash
# Provides: jungle-team
# Description: JungleScript para actualizaciones de lista de canales y de picons del equipo jungle-team
# Version: 4.0
# Date: 10/08/2020 

VERSION=4.0
LOGFILE=/tmp/enigma2_pre_start.log
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

instalar_ipk(){
	wget $URL_IPK -O $DIR_TMP/$FILE_IPK --no-check-certificate

	if [ -f  $DIR_TMP/$FILE_IPK ]; 
	then
		echo "Instalando ipk $DIR_TMP/$FILE_IPK"
		opkg update
		opkg install $DIR_TMP/$FILE_IPK
	else
		echo "No se ha podido descargar el fichero ipk: $DIR_TMP/$FILE_IPK"
	fi
}

instalar_paquetes(){
	if [ ! -f /usr/bin/rsync ];
	then
		if [ -f /etc/bhmachine ] || [ -f /etc/vtiversion.info ];
		then
			echo "instalando rsync en Blackhole/VTI..."
			arm=$(uname -a | grep -i arm)
			if [ "$arm" ]; 
			then
				echo "instalando rsync para ARM"
				URL_IPK=https://github.com/jungla-team/rsync-enigma2/raw/master/enigma2_plugin_systemplugins_rsync_3.ipk
				FILE_IPK=enigma2_plugin_systemplugins_rsync_3.ipk
				instalar_ipk
            else
				echo "instalando rsync para MIPS"
				URL_IPK=https://github.com/jungla-team/rsync-enigma2/raw/master/rsync_3.0.9-r0_mips32el.ipk
				FILE_IPK=rsync_3.0.9-r0_mips32el.ipk
				instalar_ipk
			fi
		else
			echo "Instalando rsync..."
			opkg update
			paquete=$(opkg list | grep rsync | grep tool | awk '{ print $1 }')
			if [ ! -z "${paquete}" ];
			then
				opkg install $paquete
			fi
		fi	
	fi
	if [ ! -f /bin/bash ];
	then
		echo "Instalando bash..."
		paquete="bash"
		opkg update
		opkg install $paquete
	fi
	if [ ! -f /usr/bin/curl ];
	then
		echo "Instalando curl..."
		paquete="curl"
		opkg update
		opkg install $paquete
	fi
}

actualizar_junglescript() {
	if [ "$CAMBIOS" -eq 1 ]
	then
		MENSAJE="Actualizacion automatica realizada sobre jungleScript"
		enviar_telegram "${MENSAJE}"
		echo "Copiando fichero jungleScript..."
		cp $DIR_TMP/$CARPETA/$FICHERO $DESTINO/$FICHERO
	fi
	echo "Saliendo..."
	exit 0
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
		TOKEN=$(cat ${DEST}/parametros.py | grep BOT_TOKEN | cut -d'"' -f2 | tr -d '[[:space:]]')
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
	HAY_FAV_IPTV=$(grep -il http ${DESTINO}/*.tv | grep -v streamTDT.tv | wc -l)
	EXCLUDE_FAV=exclude_fav.txt
	if [ "$HAY_FAV_TDT" -gt 0 ] || [ "$HAY_FAV_IPTV" -gt 0 ];
	then
		for i in $(ls ${DESTINO}/*.tv);
		do
			if [ "$i" != "${DESTINO}/streamTDT.tv" ];
			then
				BOUQUET_FILE=$i
				EXCLUIR_FAV_TDT=$(grep -il ee0000 ${BOUQUET_FILE} | wc -l)
				EXCLUIR_FAV_IPTV=$(grep -il http ${BOUQUET_FILE} | wc -l)
				if [ "$EXCLUIR_FAV_TDT" -eq 0 ] && [ "$EXCLUIR_FAV_IPTV" -eq 0 ];
				then
					echo "Borro bouquet: $BOUQUET_FILE $EXCLUIR_FAV_TDT $EXCLUIR_FAV_IPTV"
					rm -f $BOUQUET_FILE
				else
					BOUQUET_NAME=$(echo ${BOUQUET_FILE} | cut -d'/' -f4)
					echo "Bouquet excluido: $BOUQUET_NAME"
					echo $BOUQUET_NAME >> $DIR_TMP/$EXCLUDE_FAV
					echo -e $BOUQUET_NAME >> $DIR_TMP/excludes.txt
				fi
			fi
		done
		ls $DESTINO/*.radio $DESTINO/lamedb $DESTINO/blacklist $DESTINO/whitelist $DESTINO/satellites.xml | xargs rm
	else
		ls $DESTINO/*.tv $DESTINO/*.radio $DESTINO/lamedb $DESTINO/blacklist $DESTINO/whitelist $DESTINO/satellites.xml | xargs rm
	fi
}

recargar_lista_canales() {
	wget -qO - http://127.0.0.1/web/servicelistreload?mode=0
}

diferencias_canales() {
	DESTINO=/etc/enigma2
	LOG_RSYNC_CANALES=rsync_canales.log
	EXCLUDE_FILES=$(echo -e "README.md\nLICENSE\nsatellites.xml" > $DIR_TMP/excludes.txt)
	borrado_canales
	if [ -f $DESTINO/fav_bouquets ];
	then
		for i in $(cat $DESTINO/fav_bouquets);
		do
			ls $DIR_TMP/$CARPETA/*.tv | grep $i | cut -d'/' -f4 >> $DIR_TMP/excludes.txt
			sed -i "/$i/d" $DIR_TMP/$CARPETA/bouquets.tv
		done
	fi
	cat $DIR_TMP/excludes.txt
	rsync -aiv $DIR_TMP/$CARPETA/* $DESTINO --exclude-from=$DIR_TMP/excludes.txt --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
	FICH_SAT=satellites.xml
	RUTA_SAT=/etc/tuxbox
	rsync -aiv $DIR_TMP/$CARPETA/$FICH_SAT $RUTA_SAT/$FICH_SAT --log-file=$DIR_TMP/$LOG_RSYNC_CANALES
	if [ -f $DIR_TMP/$EXCLUDE_FAV ];
	then
		for i in $(cat ${DIR_TMP}/${EXCLUDE_FAV});
		do
			EXISTE_FAV=$(grep -i "${i}" $DESTINO/bouquets.tv | wc -l)
			if [ "$EXISTE_FAV" -eq 0 ];
			then
				echo '#SERVICE 1:7:1:0:0:0:0:0:0:0:FROM BOUQUET "'${i}'" ORDER BY bouquet' >> $DESTINO/bouquets.tv
			else
				echo "Existe favorito ${i} ya previamente en bouquets.tv"
			fi
		done
	fi
	CAMBIOS_RSYNC=$(grep -i "+++++++++" $DIR_TMP/$LOG_RSYNC_CANALES)
	if [ ! -z "${CAMBIOS_RSYNC}" ];
	then
		recargar_lista_canales
		MENSAJE="Actualizacion automatica realizada sobre los canales ${CARPETA}"
		enviar_telegram "${MENSAJE}"
		enviar_mensaje_pantalla "${MENSAJE}"
		echo $MENSAJE
	else
		echo "CAMBIOS_RSYNC esta vacía"
	fi
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
	TIPO_PICON=movistar-original
	rsync -aiv $DIR_TMP/$CARPETA/$TIPO_PICON/* $RUTA_PICONS --log-file=$DIR_TMP/$LOG_RSYNC_PICONS
    CAMBIOS_RSYNC=$(grep -i "+++++++++" $DIR_TMP/$LOG_RSYNC_PICONS)
	if [ ! -z "${CAMBIOS_RSYNC}" ];
	then
		MENSAJE="Actualizacion automatica realizada sobre los picons ${RUTA_PICONS}"
		enviar_telegram "${MENSAJE}"
		echo $MENSAJE
	else
		echo "CAMBIOS_RSYNC esta vacía"
	fi
}

redimensionamiento_picons() {
	if [ -f /etc/bhmachine ];
	then
		echo "Redimendionsando picons en sistema Blackhole"
		opkg update
		opkg install python-imaging
		URL=https://raw.githubusercontent.com/jungla-team/resize_picons/master/resizepicon.py
		CARPETA=/usr/bin/
		FICHERO=resizepicon.py
		wget $URL -O $CARPETA/$FICHERO --no-check-certificate
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
	wget -c ${download} -O $DIR_TMP/${out_file} --no-check-certificate
	if [ $? -ne 0 ];
	then
		echo "Errores al descargar $download"
		exit 1
	fi
}

wget_github_file() {
	wget $URL -O $DIR_TMP/$CARPETA/$FICHERO --no-check-certificate
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
		borrar_directorio "${DIR_TMP}/MovistarPlus-Astra" 
		borrar_directorio "${DIR_TMP}/setting_lince_astra"
		borrar_directorio "${DIR_TMP}/setting_lince_astra_hotbird"
		borrar_directorio "${DIR_TMP}/setting_astra_comunitaria"
		borrar_directorio "${DIR_TMP}/picon-movistar"
		borrar_fichero "${DIR_TMP}/MovistarPlus-Astra.zip"
		borrar_fichero "${DIR_TMP}/setting_lince_astra.zip"
		borrar_fichero "${DIR_TMP}/setting_lince_astra_hotbird.zip"
		borrar_fichero "${DIR_TMP}/setting_astra_comunitaria.zip"
		borrar_fichero "${DIR_TMP}/picon-movistar.zip"
		borrar_fichero "${DIR_TMP}/exclude_fav.txt"
		borrar_fichero "${DIR_TMP}/excludes.txt"
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

diff_github_actualizacion(){
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
		umbral=60000
	else
		umbral=30000
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
		echo "Hay espacio libre en /tmp ==> ${espacio_libre}"
	else 
		ESPACIO_PICONS="NOK"; 
		echo "No hay espacio libre en /tmp ==> ${espacio_libre}"
	fi	
}

cargar_variables_conf(){
	DIR_USR=/usr/bin
	FICH_CONFIG=$DIR_USR/enigma2_pre_start.conf
	if [ ! -f $FICH_CONFIG ];
	then
		echo "LISTACANALES=astra" > $FICH_CONFIG
		echo "PICONS=0" >> $FICH_CONFIG
	else
		existe_listacanales=$(grep -i LISTACANALES ${FICH_CONFIG} | wc -l)
		existe_picons=$(grep -i PICONS ${FICH_CONFIG} | wc -l)
		if [ "$existe_listacanales" -eq 0 ];
		then
			echo "LISTACANALES=astra" >> $FICH_CONFIG
		fi
		if [ "$existe_picons" -eq 0 ];
		then
			echo "PICONS=0" >> $FICH_CONFIG
		fi
	fi
	. $FICH_CONFIG
}

actualizar_listacanales(){
	case "$LISTACANALES" in
	'astra')
		URL=https://github.com/jungla-team/setting_lince_astra/archive/master.zip
		URL_ACTUALIZACION=https://raw.githubusercontent.com/jungla-team/setting_lince_astra/master/actualizacion
		CARPETA=setting_lince_astra
		;;
	'astra-hotbird')
		URL=https://github.com/jungla-team/setting_lince_astra_hotbird/archive/master.zip
		URL_ACTUALIZACION=https://raw.githubusercontent.com/jungla-team/setting_lince_astra_hotbird/master/actualizacion
		CARPETA=setting_lince_astra_hotbird
		;;
	'astra-comunitaria')
		URL=https://github.com/jungla-team/setting_astra_comunitaria/archive/master.zip
		URL_ACTUALIZACION=https://raw.githubusercontent.com/jungla-team/setting_astra_comunitaria/master/actualizacion
		CARPETA=setting_astra_comunitaria
		;;
	'*')
		URL=https://github.com/jungla-team/setting_lince_astra/archive/master.zip
		URL_ACTUALIZACION=https://raw.githubusercontent.com/jungla-team/setting_lince_astra/master/actualizacion
		CARPETA=setting_lince_astra
		;;
	esac

	DESTINO=/etc/enigma2
	DIR_TMP=/tmp
	ZIP=$CARPETA.zip

	if [ -f $DESTINO/actualizacion ];
	then
		FICHERO_ACTUALIZACION=$DESTINO/actualizacion
		diff_github_actualizacion
		if [ "${ACTUALIZACION}" == "YES" ];
		then
			crear_dir_tmp
			wget_github_zip $URL
			descomprimir_zip
			renombrar_carpeta
			merge_lamedb
			instalar_paquetes
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
		merge_lamedb
		instalar_paquetes
		diferencias_canales
	fi
}

actualizar_picons(){
	if [ "$PICONS" -eq 1 ];
	then
		URL=http://tropical.jungle-team.online/picon-movistar/archive/master.zip
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
					comprobar_espacio
					if [ "${ESPACIO_TMP}" = "OK" ] && [ "${ESPACIO_PICONS}" = "OK" ];
					then
						crear_dir_tmp
						wget_github_zip $URL
						descomprimir_zip
						renombrar_carpeta
						instalar_paquetes
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
					wget_github_zip $URL
					descomprimir_zip
					renombrar_carpeta
					instalar_paquetes
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

pre_actualizar_junglescript(){
	URL=https://raw.githubusercontent.com/jungla-team/enigma2_pre_start/master/enigma2_pre_start.sh
	CARPETA=junglescript
	DESTINO=/usr/bin
	FICHERO=enigma2_pre_start.sh
	DAEMON=$DESTINO/$FICHERO
	DIR_TMP=/tmp
	unset ZIP

	if [ -f $DESTINO/$FICHERO ];
	then
		crear_dir_tmp
		wget_github_file
		instalar_paquetes
		diferencias_fichero
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

#### Para realizar tareas previas a actualizar junglescript #####

pre_actualizar_junglescript

#### Limpieza en DIR_TMP

if [ ! -z "${DIR_TMP}" ];
then
	echo "Limpiando ${DIR_TMP}"
	limpiar_dir_tmp
fi

#### Como ultima instruccion meto la propia actualizacion de JungleScript

actualizar_junglescript

