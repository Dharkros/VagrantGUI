#!/bin/bash
perfil
=`zenity --entry \
--title="Añadir un perfil nuevo" \
--text="Escriba el nombre del perfil nuevo:" \
--entry-text "NewProfile"`

echo "esto es perfil: $perfil"






