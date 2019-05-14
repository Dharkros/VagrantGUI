#!/bin/bash
clear
# Variables
directorio=~/MVV
dir_actual=`pwd`


# Functiones

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

## Crea una maquina virtual.
function Crear_mkv(){
    check_d
    check_f .maquinas
	read -p 'Nombre de la maquina: ' nombre_maquina


   while [[ -d $directorio/$nombre_maquima ]]; do
   		clear
    	read -p 'Ya existe una maquina con este nombre, porfavor elija otro nombre: ' nombre_maquina	
   done

    mkdir $directorio/$nombre_maquina
    
    ## Llamamos a la funcion add_so para selecionar sistema operativo 
    Add_so
    
    ############################################
    cd $directorio/$nombre_maquina
    vagrant init $set_SO -m

    ##	Realizaremos modificaciones en el fichero Vagrantfile con el comando sed
    sed -i "/config.vm.box/a\  config.vm.network \"private_network\", type: \"dhcp\", virtualbox__intnet: \"LAN\"" Vagrantfile 

  if [[ $set_SO != 'centos/7' || $set_SO != 'centos/6' ]]; then
  	sed -i "/private_network/a\  config.vm.provider \"virtualbox\" do |vb| \n      vb.gui = true\n      vb.memory = \"1024\"\n      vb.name = \"$nombre_maquina\"\n  end\n  config.vm.provision \"shell\",inline: <<-SHELL\n     apt-get -y install python\n     echo \"vagrant:vagrant\" | chpasswd\n     echo \"root:vagrant\" | chpasswd\n  SHELL\n  config.vm.provision \"ansible\" do |ansible|\n       ansible.playbook = \"/home/dharkros/ansible-playbook/ldap_cliente.yml\"\n  end"  Vagrantfile 
  else
  	sed -i "/private_network/a\  config.vm.provider \"virtualbox\" do |vb| \n      vb.gui = false\n      vb.memory = \"1024\"\n      vb.name = \"$nombre_maquina\"\n  end"  Vagrantfile
  fi
  
  grep -iw "$nombre_maquina" $directorio/.maquinas
    
  if [[ $? -eq 1 ]]; then
        echo "$nombre_maquina:$nombre_maquina" >> $directorio/.maquinas
  fi
  
  ## Inica la estancia
  vagrant up
  #clear 
  sleep 20
  ## Muestra la IP 
  echo  "La IP de la maquina es:"
  vagrant ssh -c 'ip a'

  read -p 'Quieres conectar ahora a la maquina? ' conecssh
    conecssh=`echo $conecssh | tr [:upper:] [:lower:]`
   if [[ $conecssh == "y" || $conecssh == "yes" || $conecssh == "s" || $conecssh == "si" ]]; then
        vagrant ssh
   fi
  cd $dir_actual
}

