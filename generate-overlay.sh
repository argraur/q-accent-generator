#!/bin/bash
#
# Copyright (C) 2018-2019 The Pixel3ROM Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

throw_error() {
    echo "FAILED: $1"; exit 1
}

to_lowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

remove_space() {
    echo "$1" | sed 's+ ++'
}

zip_module() {
    cd $1
    zip -r4 ../$1.zip *
    cd ../
}

clear

echo "Welcome to Q Accent Generator!"
echo ""
sleep 1

echo -n "Name of the new accent: "
read COLOR_NAME

COLOR_NAME_NOSPACE=$(remove_space "$COLOR_NAME")
COLOR_NAME_LOWERCASE=$(to_lowercase "$COLOR_NAME_NOSPACE")

echo ""

echo -n "Accent for dark theme: "
read DARK_ACCENT
DARK_ACCENT=$(to_lowercase $DARK_ACCENT)
echo ""

STEPS=4

if test "$1" = "-m"; then STEPS=$(($STEPS + 1)); fi
echo "Leave empty to use accent on dark theme: "
echo -n "Accent for light theme: "
read LIGHT_ACCENT
if test -z $LIGHT_ACCENT; then LIGHT_ACCENT=$DARK_ACCENT; fi
LIGHT_ACCENT=$(to_lowercase $LIGHT_ACCENT)
echo ""

echo -n "[1/$STEPS] Unpacking template..."
unzip -d $COLOR_NAME_LOWERCASE tools/template.zip > /dev/null
echo " Done"

echo -n "[2/$STEPS] Generating overlay..."
sed -i "s+COLORNAME+$COLOR_NAME_LOWERCASE+" $COLOR_NAME_LOWERCASE/{AndroidManifest.xml,res/values/public.xml,res/values/strings.xml}
sed -i "s+NAME+$COLOR_NAME_NOSPACE+" $COLOR_NAME_LOWERCASE/apktool.yml
sed -i "s+NAME+$COLOR_NAME+" $COLOR_NAME_LOWERCASE/res/values/strings.xml
sed -i "s+DARK_COLOR+$DARK_ACCENT+" $COLOR_NAME_LOWERCASE/res/values/colors.xml
sed -i "s+LIGHT_COLOR+$LIGHT_ACCENT+" $COLOR_NAME_LOWERCASE/res/values/colors.xml
echo " Done"

echo -n "[3/$STEPS] Building overlay..."
java -jar tools/apktool.jar --quiet b $COLOR_NAME_LOWERCASE
if [ ! $? == 0 ]; then throw_error "Error during building overlay"; fi
echo " Done"

echo -n "[4/$STEPS] Signing overlay..."
signapk tools/platform.x509.pem tools/platform.pk8 \
    $COLOR_NAME_LOWERCASE/dist/AccentColor"$COLOR_NAME_NOSPACE"Overlay.apk \
    AccentColor"$COLOR_NAME_NOSPACE"Overlay.apk
echo " Done"

rm -rf $COLOR_NAME_LOWERCASE

if test "$1" = "-m"; then
    echo -n "[5/$STEPS] Generating Magisk module... "

    unzip -d $COLOR_NAME_LOWERCASE-magisk tools/template-magisk.zip >/dev/null

    sed -i "s+COLOR_NAME+$COLOR_NAME_LOWERCASE+" $COLOR_NAME_LOWERCASE-magisk/module.prop
    sed -i "s+MODULE_NAME+$COLOR_NAME+" $COLOR_NAME_LOWERCASE-magisk/module.prop

    mkdir $COLOR_NAME_LOWERCASE-magisk/system/product/overlay/AccentColor"$COLOR_NAME_NOSPACE"
    cp AccentColor"$COLOR_NAME_NOSPACE"Overlay.apk $COLOR_NAME_LOWERCASE-magisk/system/product/overlay/AccentColor"$COLOR_NAME_NOSPACE"/AccentColor"$COLOR_NAME_NOSPACE"Overlay.apk
    zip_module $COLOR_NAME_LOWERCASE-magisk >/dev/null
    rm -rf $COLOR_NAME_LOWERCASE-magisk

    echo " Done"
    echo ""
    echo "$COLOR_NAME package: AccentColor"$COLOR_NAME_NOSPACE"Overlay.apk"
    echo "Magisk Module: $COLOR_NAME_LOWERCASE-magisk.zip"
else
    echo ""
    echo "$COLOR_NAME package: AccentColor"$COLOR_NAME_NOSPACE"Overlay.apk"
fi
