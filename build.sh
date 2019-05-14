#!/bin/bash
clear
# Variables
directorio=~/MVV
dir_actual=`pwd`

# Functiones

## Esta funcion que introduce una pausa hata pulsar la tecla "Enter".
function Pausa(){
	echo ""
	read -p 'Pulse una tecla "Enter" para continuar...'
	clear
}

## Verifica si el directorio existe y en caso que no lo crea.
function check_d(){

	if ! [[ -d $directorio ]]; then
		mkdir $directorio
	fi
}

## Verifica si el ficero existe y en caso que no lo crea.
function check_f(){

	if ! [[ -f $directorio/$1 ]]; then
		touch $directorio/$1
	fi
}

## Cambia el nombre de una maquina virtual.
function cambiar_nombre_mkv(){

    cat $directorio/.maquinas | awk -F":" '{print $2}' | nl
    read -p 'Seleciones la maquina a modificar: ' select_nombre
    clear
    echo 'Cual sera el nuevo nombre?'
    read -p 'Nombre: ' new_name

    cd $directorio/$(cat $directorio/.maquinas | sed -n "$select_nombre p" | awk -F":" '{print $1}')
    grep -iw "vb.name =" Vagrantfile > /dev/null 2>&1
   
    if [[ $? -ne 0 ]]; then
        sed -i '2a\ config.vm.provider "virtualbox" do |vb|' Vagrantfile
        sed -i "3a\ \ \ vb\.name = \"$new_name\"" Vagrantfile
        sed -i '4a\ end' Vagrantfile
    else
        sed -i "s/vb\.name = \".*/vb\.name = \"$new_name\"/" Vagrantfile
    fi
    vagrant reload
   cd $dir_actual
}

## Crea una maquina virtual.
function Crear_mkv(){
    check_d
    check_f .maquinas
    read -p 'Nombre de la carpeta: ' nombre_carpeta

    while [[ -d $directorio/$nombre_carpeta ]]; do
    clear
    read -p 'La carpeta ya existe, porfavor elija otro nombre: ' nombre_carpeta	
    done

    mkdir $directorio/$nombre_carpeta
    Add_so
    cd $directorio/$nombre_carpeta
    echo $set_SO
    vagrant init $set_SO -m
    
   
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

## Seleciona el sistema operativo que usara la maquina virtual.
function Add_so(){
    echo "1. Ubuntu 18.04 (64/32 bits)"
    echo "2. Ubuntu 16.04 (64/32 bits)"
    echo "3. Ubuntu 14.04 (64/32 bits)"
    echo "4. Centos 7"
    echo "5. Centos 6"
    #echo "6. Windows 10 (64 bits)"
    read -p 'Introduce una opcion: ' opcion_add
    if [[ $opcion_add -lt 4 ]]; then
    	read -p '64 bits o 32 bits: ' arquitertura
    fi
    while [[ $arquitertura -ne '32' && $arquitertura -ne '64' && $opcion_add -lt 4 ]]; do
	clear
	read -p 'Escriba 64 para usar una de distro de "64 bits" y 32 pra usar una de "32 bits": ' arquitertura	
    done
    case $opcion_add in
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
        #6 )
         #   set_SO="dharkros/windows10";;
        *)
            ;;

    esac

}

## Elemina maquina virtual.
function Rm_mkv(){
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

## Edita caracteristica de la maquina virtual.
function Edit_mkv(){
    echo "1. Cambiar Nombre"
    echo "2. Direccion IP"
    echo "3. Adaptador De  Red"
    echo "4. USO De RAM"
    echo "5. USO De CPUS"
    echo "6. Añadir HDD"
    read -p 'Introduce una opcion: ' opcion_editar
    clear
   case  $opcion_editar in
        1) 
            cambiar_nombre_mkv;;
        *) 
            ;;
   esac
}
## Conecta mediante ssh a la maquina virtual.
function Cx_mkv(){
   cat $directorio/.maquinas | awk -F":" '{print $2}' | nl
   read -p 'Seleciones la maquina a conectar: ' select_ssh
   
   cd $directorio/$(cat $directorio/.maquinas | sed -n "$select_ssh p" | awk -F":" '{print $1}')
   clear
   vagrant ssh
   cd $dir_actual
}

## Menú maid

while [[ true ]]; do
    echo "1. Crear Maquina"
    echo "2. Borrar Maquina"
    echo "3. Conectar a MKV"
    echo "4. Editar Maquina"
    echo "5. Salir"
    #echo "6. CONTROLADOR DE INSTANTANEAS"
    #echo "7. Aprovicionar MKV"

    read -p 'Introduce una opcion: ' opcion
    case $opcion in
    1)
        clear
        Crear_mkv
        Pausa;;

    2)
        clear
        Rm_mkv
        Pausa;;

    3)
        clear
        Cx_mkv
        clear;;
    4)
        clear
        Edit_mkv
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
