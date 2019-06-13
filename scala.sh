#!/bin/sh

TotalRam=`cat /proc/meminfo | head -n1 | awk '{print $2/1024}' | awk -F"." '{print $1}'`

cambiar_ram=`zenity --scale --text="Selecione la cantidad de memoria RAM." --value=1024 --max-value=$TotalRam --min-value=512`

sed -i "s/vb\.memory = \".*/vb\.memory = \"$cambiar_ram\"/" ~/MKV/ubu/Vagrantfile



echo "************************************************************"

cat ~/MKV/ubu/Vagrantfile
