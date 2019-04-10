#!/bin/bash

clear
# Variables

directorio=~/MVV

# Functiones

function pausa(){
	echo ""
	read -p 'Pulse una tecla "Enter" para continuar...'
	clear
}

function check_d(){

	if ! [[ -d $directorio ]]; then
		mkdir $directorio
	fi
}

function check_f(){

	if ! [[ -f $directorio/$1 ]]; then
		touch $directorio/$1
	fi
}

function crear_mv(){
    check_d
    read -p 'Nombre de la carpeta: ' ubicacion

    while [[ -d $directorio/$ubicacion ]]; do
			clear
			read -p 'La carpeta ya existe, porfavor elija otro nombre: '  ubicacion	
	done
    
    mkdir $directorio/$ubicacion
    add_so
    dir_actual=`pwd`
    cd $directorio/$ubicacion
    pwd 
    echo $set_SO
    #vagrant init $set_SO 
    #vagrant up
    cd $dir_actual
    pwd
}

function add_so(){
    echo "1. Ubuntu 18.04 (64/32 bits)"
    echo "2. Ubuntu 16.04 (64/32 bits)"
    echo "3. Ubuntu 14.04 (64/32 bits)"
    echo "4. Centos 7"
    echo "5. Centos 6"
    echo "6. Windows 10 (64 bits)"
    read -p 'Introduce una opcion: ' opcion
    read -p '64 bits o 32 bits: ' arquitertura
    while [[ $arquitertura != '32' && $arquitertura != '64' ]]; do
			clear
			read -p 'Escriba 64 para usar una de distro de "64 bits" y 32 pra usar una de "32 bits": ' arquitertura	
	done
    case $opcion in
        1 )
            set_SO="ubuntu/bionic$arquitertura";;
        2 )
            set_SO="ubuntu/xenial$arquitertura";;
        3 )
            set_SO="ubuntu/trusty$arquitertura";;
        4 )
            set_SO="centos/7";;
        5 )
            set_SO="centos/6";;
        6 )
            set_SO="dharkros/windows10";;
        *)
            ;;

    esac

}



























echo "1. Crear maquina"
echo "2. Borrar maquina"
echo "3. Editar maquina"
read -p 'Introduce una opcion: ' opcion
case $opcion in
    1 )
		crear_mv;;
	*)
		;;

esac
