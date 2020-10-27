#!/bin/bash

DIR_SRC=./
DIR_RELEASES=$DIR_SRC/ipk
DIR_IPK_TMP=$DIR_SRC/tmp

NEW_VERSION=$(grep "VERSION=" ${DIR_SRC}/enigma2_pre_start.sh | cut -d'=' -f2)
NEW_VERSION=$(eval echo $NEW_VERSION)

DIR_PKG_BUILD=$DIR_SRC/package
DIR_PKG_DEST=$DIR_PKG_BUILD/usr/bin
TYPE="all"
PKG_NAME=junglescript_${NEW_VERSION}_all

echo "Building package $PKG_NAME"

cp -rf $DIR_SRC/enigma2_pre_start.* $DIR_PKG_DEST
newLine="Version: ${NEW_VERSION}"
sed -i "2s/.*/${newLine}/" $DIR_PKG_BUILD/CONTROL/control
  
ipkg-build ${DIR_PKG_BUILD}

mkdir -p ${DIR_RELEASES}
cp -p ${PKG_NAME}.ipk ${DIR_RELEASES}/junglescript_${NEW_VERSION}_${TYPE}.ipk
echo "Moved ${PKG_NAME}.ipk to ${DIR_RELEASES}/junglescript_${NEW_VERSION}_${TYPE}.ipk"
cp -p ${PKG_NAME}.ipk ${DIR_RELEASES}/junglescript_${TYPE}.ipk
echo "Moved ${PKG_NAME}.ipk to ${DIR_RELEASES}/junglescript_${TYPE}.ipk"
rm ${PKG_NAME}.ipk
rm -rf ${DIR_IPK_TMP}