#!/bin/bash
clear
# Variables
directorio=~/MVV
dir_actual=`pwd`

# Functiones

function Pausa(){
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

function Crear_mv(){
    check_d
    read -p 'Nombre de la carpeta: ' nombre_carpeta

    while [[ -d $directorio/$nombre_carpeta ]]; do
    clear
    read -p 'La carpeta ya existe, porfavor elija otro nombre: ' nombre_carpeta	
    done

    mkdir $directorio/$nombre_carpeta
    Add_so
    cd $directorio/$nombre_carpeta
    echo $set_SO
    vagrant init $set_SO 
    
   
    read -p 'Nombre de la maquina: ' nombre_maquinas
    grep -iw "$nombre_maquinas" $directorio/.maquinas
    
    if [[ $? -eq 1 ]]; then
        echo "$nombre_carpeta:$nombre_maquinas" >> $directorio/.maquinas
    fi
    vagrant up
    
    read -p 'Quieres conectar ahora a la maquina? ' conecssh
    conecssh=`echo $conecssh | tr [:upper:] [:lower:]`
   if [[ $conecssh == "y" || $conecssh == "yes" || $conecssh == "s" || $conecssh == "si" ]]; then
        vagrant ssh
   fi
    cd $dir_actual
}

function Add_so(){
    echo "1. Ubuntu 18.04 (64/32 bits)"
    echo "2. Ubuntu 16.04 (64/32 bits)"
    echo "3. Ubuntu 14.04 (64/32 bits)"
    echo "4. Centos 7"
    echo "5. Centos 6"
    echo "6. Windows 10 (64 bits)"
    read -p 'Introduce una opcion: ' opcion
    if [[ $option -lt 4 ]]; then
    	read -p '64 bits o 32 bits: ' arquitertura
    fi
    while [[ $arquitertura -ne '32' && $arquitertura -ne '64' && $opcion -lt 4 ]]; do
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

function Rm_mv(){
   cat $directorio/.maquinas | awk -F":" '{print $2}' | nl
   read -p 'Seleciones cual borrar: ' select_drop
   echo "Se va a eliminar $(cat $directorio/.maquinas | sed -n "$select_drop p" | awk -F":" '{print $2}')"
   read -p '¿Deseas continuar? (y/n) ' resp
   resp=`echo $resp | tr [:upper:] [:lower:]`
   if [[ $resp == "y" || $resp == "yes" || $resp == "s" || $resp == "si" ]]; then
      cd $directorio/$(cat $directorio/.maquinas | sed -n "$select_drop p" | awk -F":" '{print $1}')
      vagrant destroy -f
      cd $dir_actual
      rm -r $directorio/$(cat $directorio/.maquinas | sed -n "$select_drop p" | awk -F":" '{print $1}')
      cat $directorio/.maquinas | sed -i "$select_drop d" $directorio/.maquinas
      sleep 2s
   fi   
} 

function Edit_mv(){
   clear
}

function Cx_mv(){
   cat $directorio/.maquinas | awk -F":" '{print $2}' | nl
   read -p 'Seleciones la maquina a conectar: ' select_ssh
   
   cd $directorio/$(cat $directorio/.maquinas | sed -n "$select_ssh p" | awk -F":" '{print $1}')
   vagrant ssh
   cd $dir_actual
}

while [[ true ]]; do
    echo "1. Crear maquina"
    echo "2. Borrar maquina"
    echo "3. Conectar a mv"
    echo "4. Editar maquina"
    echo "5. Salir"
    read -p 'Introduce una opcion: ' opcion
    case $opcion in
    1)
        check_f .maquinas
        Crear_mv
        Pausa;;

    2)
        Rm_mv
        Pausa;;

    3)
        Cx_mv
        clear;;
    4)
        Edit_mv
        Pausa;;

    5)
        exit
        clear;;
    remove)
          rm -rf ~/MVV/*;;
    *)
        ;;

    esac

done
