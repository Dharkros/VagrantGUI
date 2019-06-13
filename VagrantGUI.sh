#!/bin/bash
clear
# Variables
directorio=~/MKV
dir_actual=`pwd`

## Instala las dependencias

function Dependencias(){
  which $1  > /dev/null 2>&1
  if [[ $? -ne 0 && $1 != "notify-send" ]]; then
    instalar="n"
    echo "$1 no esta instalado deseas instalarlo"
    read -p 'Respuesta(y/n): ' instalar
    if [[ "$instalar" == "y" ]]; then
      sudo apt install $1
      notify-send Bien: "DEPENDENCIAS INSTALADAS" -t 5000
    else
      clear
      echo "Sin $1 VagrantGUI no funciona, porfavor instalelo para utilizarlo"
      exit
    fi

  fi

  which $1  > /dev/null 2>&1
  if [[ $? -ne 0 && $1 == "notify-send" ]]; then
    Dependencias libnotify-bin
  fi
}
## Esta funcion que introduce una pausa hata pulsar la tecla "Enter".
function Pausa(){
	echo ""
	read -p 'Pulse una tecla "Enter" para continuar...'
	clear
}

## Verifica si el directorio existe y en caso que no lo crea.
function check_d(){

	if ! [[ -d "$directorio" ]]; then
		mkdir "$directorio"
	fi
}

## Verifica si el ficero existe y en caso que no lo crea.
function check_f(){

	if ! [[ -f "$directorio"/$1 ]]; then
		touch "$directorio"/$1
	fi
}

## Cambia el nombre de una maquina virtual.
function cambiar_nombre_mkv(){
    clear
    cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl

    read -p 'Seleciones la maquina a modificar: ' select_nombre
    clear
    new_name=`zenity --entry \
      --title="Nuevo nombre" \            
      --text="Escriba el nuevo nombre:" \
      --entry-text "Nuevo nombre"`                        
    
    new_name=`echo "$new_name" | tr -s '[[:space:]]' '_' | sed 's/_*$//'`

    cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_nombre p" | awk -F":" '{print $1}')
    grep -iw "vb.name =" Vagrantfile > /dev/null 2>&1
   
    if [[ $? -ne 0 ]]; then
        sed -i '2a\ config.vm.provider "virtualbox" do |vb|' Vagrantfile
        sed -i "3a\ \ \ vb\.name = \"$new_name\"" Vagrantfile
        sed -i '4a\ end' Vagrantfile
    else
        sed -i "s/vb\.name = \".*/vb\.name = \"$new_name\"/" Vagrantfile
    fi
    vagrant reload
    mv "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_nombre p" | awk -F":" '{print $1}') "$directorio"/$new_name
    sed -i "s/$(cat "$directorio"/.maquinas | sed -n "$select_nombre p" | awk -F":" '{print $1}'):/$new_name:/" "$directorio"/.maquinas
    cd "$dir_actual"
    notify-send Bien: "NOMBRE ACTUALIZADO" -t 5000
}

## Modifica la opciones de MEMORIA

function Asignar_ram(){
    clear
   	cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   	echo "     salir"

  	read -p 'Seleciones una maquina": ' select_ram

    cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_ram p" | awk -F":" '{print $1}')

	  TotalRam=`cat /proc/meminfo | head -n1 | awk '{print $2/1024}' | awk -F"." '{print $1}'`

	  cambiar_ram=`zenity --scale --text="Selecione la cantidad de memoria RAM." --value=1024 --max-value=$TotalRam --min-value=512`
	  sed -i "s/vb\.memory = \".*/vb\.memory = \"$cambiar_ram\"/" Vagrantfile
	
	  cd "$dir_actual"
}

##  Modifica la opciones de CPUS

function Asignar_cpus(){
    clear
   	cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   	echo "     salir"

  	read -p 'Seleciones una maquina": ' select_Cpu

    cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_Cpu p" | awk -F":" '{print $1}')

	  TotalCpu=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $4}'`

	  cambiar_Cpu=`zenity --scale --text="Selecione la cantidad de CPUs." --value=1 --max-value=$TotalCpu --min-value=1`
	  sed -i "s/vb\.cpus = \".*/vb\.cpus = \"$cambiar_Cpu\"/" Vagrantfile
	
	  cd "$dir_actual"
}


## Modifica la opciones de red

function Asignar_red(){
    clear
   	cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   	echo "     salir"

  	read -p 'Seleciones una maquina": ' select_red

    cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_red p" | awk -F":" '{print $1}')


## Introducir IP

    read -p 'DHCP/IP: ' new_ip

    new_ip=`echo $new_ip | tr -s [[:upper:]] [[:lower:]]`

    if [[ $new_ip == "ip" ]];then
        grep "config.vm.network \"public_network\", type: \"dhcp\"" Vagrantfile > /dev/null 2>&1

        if [[ $? -eq 0 ]];then

            cambio_ip=`zenity --entry \
              --title="Nueva IP" \            
              --text="Escriba la nueva IP:" \
              --entry-text "Nuevo IP"`   

            sed -i "s/config\.vm\.network\ \"public_network\",\ type:\ \"dhcp\"/config\.vm\.network\ \"public_network\",\ ip:\ \"$cambio_ip\"/" Vagrantfile
        fi

    elif [[ $new_ip == "dhcp" ]];then
      sed  -i "s/config\.vm\.network\ \"public_network\",\ ip:\ \".*/config\.vm\.network\ \"public_network\",\ type:\ \"dhcp\"/" Vagrantfile
    
    else
        notify-send Error "Red: Opion no valida" -t 10000
    fi

	  cd "$dir_actual"
} 

## Crea una maquina virtual.

function Crear_mkv(){
    check_d
    check_f .maquinas


    nombre_maquina=`zenity --entry \
	    --title="Crear maquina" \
	    --text="Escriba el nombre de la maquina:" \
	    --entry-text "Nombre de la nueva maquina"`                        


    nombre_maquina=`echo "$nombre_maquina" | tr -s '[[:space:]]' '_' | sed 's/_*$//'`
    while [[ -d "$directorio"/"$nombre_maquina" ]]; do
        clear
         nombre_maquina=`zenity --entry \
	    --title="Crear maquina" \
	    --text="Ya existe una maquina con este nombre, porfavor elija otro nombre:"\
	    --entry-text "Nombre de la nueva maquina"`  

    done

   mkdir "$directorio"/"$nombre_maquina"
    
   ## Llamamos a la funcion add_so para selecionar sistema operativo 
   Add_so
    
   cd "$directorio"/"$nombre_maquina"
   
   ## Creacion del fichero vagrant
   vagrant init $set_SO -m

   ##  Realizaremos modificaciones en el fichero Vagrantfile con el comando sed para crear un fichero basico depemdiendo de la familia del SO
   
   sed -i "/config.vm.box/a\  config.vm.network \"public_network\", type: \"dhcp\"" Vagrantfile
   ## POR ALGUNA RAZON NO PUEDO PONER  2 IF CON || EN UN SOLO IF
   if [[ "$set_SO" == "centos/7" ]];then
        sed -i "/config.vm.network/a\  config.vm.provider \"virtualbox\" do |vb| \n      vb.gui = false\n      vb.memory = \"1024\"\n      vb.cpus = \"1\"\n      vb.name = \"$nombre_maquina\"\n  end\n  config.vm.provision \"shell\",inline: <<-SHELL\n    yum -y install python\n     echo \"vagrant:vagrant\" | chpasswd\n     echo \"root:vagrant\" | chpasswd\n     sed -i 's/PermitRootLogin/#PermitRootLogin/' /etc/ssh/sshd_config\n     sed -i '/PermitRootLogin/a\PermitRootLogin yes' /etc/ssh/sshd_config\n     systemctl reload sshd\n     sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config\n  SHELL"  Vagrantfile
   elif [[ "$set_SO" == "centos/6" ]]; then
 
     sed -i "/config.vm.network/a\  config.vm.provider \"virtualbox\" do |vb| \n      vb.gui = false\n      vb.memory = \"1024\"\n      vb.cpus = \"1\"\n      vb.name = \"$nombre_maquina\"\n  end\n  config.vm.provision \"shell\",inline: <<-SHELL\n    yum -y install python\n     echo \"vagrant:vagrant\" | chpasswd\n     echo \"root:vagrant\" | chpasswd\n     sed -i 's/PermitRootLogin/#PermitRootLogin/' /etc/ssh/sshd_config\n     sed -i '/PermitRootLogin/a\PermitRootLogin yes' /etc/ssh/sshd_config\n     service sshd restart\n     sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config\n  SHELL"  Vagrantfile
   else
     sed -i "/config.vm.network/a\  config.vm.provider \"virtualbox\" do |vb| \n      vb.gui = false\n      vb.memory = \"1024\"\n      vb.cpus = \"1\"\n      vb.name = \"$nombre_maquina\"\n  end\n  config.vm.provision \"shell\",inline: <<-SHELL\n     apt-get -y install python\n     echo \"vagrant:vagrant\" | chpasswd\n     echo \"root:vagrant\" | chpasswd\n     sed -i 's/PermitRootLogin/#PermitRootLogin/' /etc/ssh/sshd_config\n     sed -i '/PermitRootLogin/a\PermitRootLogin yes' /etc/ssh/sshd_config\n     systemctl reload sshd\n     sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config\n  SHELL"  Vagrantfile 
   fi
  
   grep -iw "$nombre_maquina" "$directorio"/.maquinas
    
   if [[ $? -eq 1 ]]; then
        echo "$nombre_maquina:" >> "$directorio"/.maquinas
   fi
  
   ## Inicia la estancia
   vagrant up |  zenity --progress --pulsate --auto-close

# Notificacion
   notify-send Bien: "MAQUINA \"$(echo "$nombre_maquina" | tr [:lower:] [:upper:])\" EN FUNCIONAMIENTO!" -t 5000
   clear   
   
   ## Muestra la IP 
   echo  "La IP de la maquina es:"
   vagrant ssh -c 'ip a'
   Pausa
   read -p 'Quieres conectar ahora a la maquina? ' conecssh
     conecssh=`echo $conecssh | tr [:upper:] [:lower:]`
   if [[ $conecssh == "y" || $conecssh == "yes" || $conecssh == "s" || $conecssh == "si" ]]; then
        vagrant ssh
   fi
   cd "$dir_actual"
}

## Seleciona el sistema operativo que usara la maquina virtual.
function Add_so(){
    echo "1. Ubuntu 18.04 (64/32 bits)"
    echo "2. Ubuntu 16.04 (64/32 bits)"
    echo "3. Ubuntu 14.04 (64/32 bits)"
    echo "4. Centos 7"
    echo "5. Centos 6"
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
        *)
            clear
            echo "Debes de elegir uno de los siguiente S.O:"
            echo ""
            Add_so;;

    esac

}

## Elimina maquina virtual.
function Rm_mkv(){
   cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   echo "     salir"
   
   
   read -p 'Seleciones cual borrar o "salir": ' select_drop
   
   
   if [[ $select_drop -le $(wc -l "$directorio"/.maquinas | awk '{print $1}') && $select_drop != "salir" ]];then
        echo "Se va a eliminar $(cat "$directorio"/.maquinas | sed -n "$select_drop p" | awk -F":" '{print $1}')"
        read -p '¿Deseas continuar? (y/n) ' resp
        resp=`echo $resp | tr [:upper:] [:lower:]`
        if [[ $resp == "y" || $resp == "yes" || $resp == "s" || $resp == "si" ]]; then
            cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_drop p" | awk -F":" '{print $1}')
            vagrant destroy -f > /dev/null 2>&1
            cd "$dir_actual"
	    rm -r "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_drop p" | awk -F":" '{print $1}')
            cat "$directorio"/.maquinas | sed -i "$select_drop d" ""$directorio""/.maquinas
            sleep 2
        fi   
   else
	clear
	if [[ $select_drop != "salir" ]];then

	   zenity --notification\
		   --window-icon="error" \
		   --text="Opcion \"$select_drop\" no valida"
   	fi
   fi
} 

## Edita caracteristica de la maquina virtual.
function Edit_mkv(){
    echo "1. CAMBIAR NOMBRE"
    echo "2. DIRECCIÓN IP"
    echo "3. USO DE RAM"
    echo "4. USO DE CPUs"
#    echo "6. Añadir HDD"
    echo "salir"
    read -p 'Introduce una opcion: ' opcion_editar
    clear
   case  $opcion_editar in
        1) 
            cambiar_nombre_mkv;;
        2) 
            Asignar_red;;
	      3)
		        Asignar_ram;;
	      4)
		        Asignar_cpus;;
        salir)
          ;;
        *) 
            ;;
   esac
}
## Conecta mediante ssh a la maquina virtual.
function Cx_mkv(){
   cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   read -p 'Seleciones la maquina a conectar: ' select_ssh
   
   cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_ssh p" | awk -F":" '{print $1}')
   clear
   vagrant ssh

   if [[ $? -ne 0 ]];then
notify-send Error "No se puede estrablecer la conexion. Puede que la maquina no este en funcionamiento" -t 10000
   fi
   cd "$dir_actual"
}

## Controla las sentencia Apagar/reiniciar/suspender
function c_init(){
   echo "1. Iniciar"
   echo "2. Apagar"
   echo "3. Reinicia"
   echo "4. Suspender"
   echo "salir"
   
   read -p 'Elige una opcion: ' comando_init

   cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   read -p 'Seleciones una maquina: ' select_maquina_init
   
   cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_maquina_init p" | awk -F":" '{print $1}')
   clear
   case $comando_init in
     1 )
       vagrant up;;
     2 )
       vagrant halt;;
     3 )
       vagrant reload;;
     4 )
       vagrant suspend;;
    salir)
      ;;
     * )
       c_init;;
   esac
   cd "$dir_actual"
}

## Controla la administracion de instantaneas
function c_snapshot(){

   cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
   read -p 'Seleciones una maquina: ' select_maquina_snapshot
   cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_maquina_snapshot p" | awk -F":" '{print $1}')
   clear
   echo "1. Listar snapshot"
   echo "2. Crear snapshot"
   echo "3. Restaura snapshot"
   echo "4. Eliminar snapshot"
   echo "salir"

   read -p 'Elige una opcion: ' comando_snapshot
   
   clear
   case $comando_snapshot in
     1 )
       vagrant snapshot list;;
     2 )
       read -p 'Nombre snapshot: ' name_snapshot
       vagrant snapshot save $name_snapshot;;
     3 )
       vagrant snapshot list
       read -p 'Nombre snapshot: ' name_snapshot_res
       vagrant snapshot  restore $name_snapshot_res;;
     4 )
       vagrant snapshot list
       read -p 'Nombre snapshot: ' name_snapshot_delete
       vagrant snapshot  delete $name_snapshot_delete;;
     salir) 
        ;;
     * )
       c_snapshot;;
   esac
   cd "$dir_actual"
}

function provision(){
    if [[ "$git" == "true" ]];then
    	  cat "$directorio"/.maquinas | awk -F":" '{print $1}' | nl
    	  read -p 'Seleciones una maquina: ' select_maquina_provision
       	cd "$directorio"/$(cat "$directorio"/.maquinas | sed -n "$select_maquina_provision p" | awk -F":" '{print $1}')
       	clear
       	echo "1. LDAP client (Solo Ubuntu)"
       	echo "2. Apache2 (solo Ubuntu)"   
       	echo "3. REINICIAR Y APROVISIONAR" 
        echo "salir"
       	read -p 'Seleciona que provision decea hace: ' set_provision

       	case $set_provision in
    	      1 )
                    grep -w "ldap_cliente.yml" Vagrantfile > /dev/null 2>&1

                    if [[ $? -eq 0 ]]; then
                       clear
                       echo "Ya esta aprovicionado con LDAP client"
                    else
                       sed -i 's/vb.gui = false/vb.gui = true/' Vagrantfile
        		           sed -i "/\ SHELL/a\  config.vm.provision \"ansible\" do |ansible|\n       ansible.playbook = \"/home/$(whoami)/ansible-playbook/ldap_cliente.yml\"\n  end" Vagrantfile
                       clear
                       Reload_provision
                    fi;;
            2 )
                    grep -w "install_apache2.yml" Vagrantfile > /dev/null 2>&1

                    if [[ $? -eq 0 ]]; then
                       clear
                       echo "Ya esta aprovicionado con Apache2"
                    else
                       sed -i "/\ SHELL/a\  config.vm.provision \"ansible\" do |ansible|\n       ansible.playbook = \"/home/$(whoami)/ansible-playbook/install_apache2.yml\"\n  end" Vagrantfile
                       clear
                       Reload_provision
                    fi;;

    	      3 )
    		           vagrant reload --provision;;
                   
    	      salir)
              ;;
             * )
    	   	         ;;
       	esac
   	    cd "$dir_actual"
    else
	      echo "El directorio ansible-playbook no existe"
    fi
   
}

function sync_provision(){
git=false

if ! [[ -d ~/ansible-playbook ]];then
	which git
	if [[ "$?" != 0 ]];then
		echo "git no esta instalado, porfavor instale git para realizar esta accion"
        else
		cd ~
		git clone https://github.com/Dharkros/ansible-playbook.git
		cd "$dir_actual"
		git=true
	fi
else
	cd ~/ansible-playbook
	git pull
	cd "$dir_actual"
        git=true

fi
}

function Reload_provision(){
  read -p 'Quieres reiniciar para aprovicionar la maquina ahora? ' reload_now
     reload_now=`echo $reload_now | tr [:upper:] [:lower:]`
   if [[ $reload_now == "y" || $reload_now == "yes" || $reload_now == "s" || $reload_now == "si" ]]; then
        vagrant reload --provision
   fi
}



## Instalacion de dependencias

Dependencias vagrant
Dependencias virtualbox
Dependencias ansible
Dependencias notify-send
Dependencias zenity
clear
## Menú maid
while [[ true ]]; do
    echo "1. Crear Maquina"
    echo "2. Borrar Maquina"
    echo "3. Conectar a MKV"
    echo "4. Editar Maquina"
    echo "5. Controlador de snapshot"
    echo "6. Aprovisionar MKV"
    echo "7. Iniciar/Apagar/reiniciar/suspender"
    echo "8. Salir"

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
        clear
        c_snapshot
        Pausa;;
    6)
        clear
        sync_provision
	      provision
        Pausa;;
    7)
        clear
        c_init
        Pausa;;

    8)
        clear
	echo "Adios!!!"
	sleep 2
	clear
	exit;;
    remove)
          rm -rf ~/MKV;;
    *)
        ;;

    esac

done
