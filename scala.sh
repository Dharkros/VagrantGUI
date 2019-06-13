#!/bin/sh

VALUE=`zenity --scale --text="Selecione la cantidad de memoria RAM." --value=1024 --max-value=8000 --min-value=512`

case $? in
         0)
		echo "Ha seleccionado $VALUE MB de RAM.";;
         1)
                echo "No ha seleccionado ningún valor.";;
        -1)
                echo "An unexpected error has occurred.";;
esac
