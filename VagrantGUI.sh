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
## Esta funcion que introduce una  hata pulsar la tecla "Enter".
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
    select_nombre=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))

    new_name=`zenity --entry \
      --title="Nuevo nombre" \            
      --text="Escriba el nuevo nombre:" \
      --entry-text "Nuevo nombre"`                        
    
    new_name=`echo "$new_name" | tr -s '[[:space:]]' '_' | sed 's/_*$//'`

    cd "$directorio"/"$select_nombre"

    grep -iw "vb.name =" Vagrantfile > /dev/null 2>&1
   
    if [[ $? -ne 0 ]]; then
        sed -i '2a\ config.vm.provider "virtualbox" do |vb|' Vagrantfile
        sed -i "3a\ \ \ vb\.name = \"$new_name\"" Vagrantfile
        sed -i '4a\ end' Vagrantfile
    else
        sed -i "s/vb\.name = \".*/vb\.name = \"$new_name\"/" Vagrantfile
    fi
    vagrant reload
    mv "$directorio"/$select_nombre "$directorio"/$new_name
    sed -i "s/$select_nombre:/$new_name:/" "$directorio"/.maquinas
    cd "$dir_actual"
    notify-send Bien: "NOMBRE ACTUALIZADO" -t 5000
}

## Modifica la opciones de MEMORIA

function Asignar_ram(){
    clear
    select_ram=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))

    cd "$directorio"/$select_ram 

	  TotalRam=`cat /proc/meminfo | head -n1 | awk '{print $2/1024}' | awk -F"." '{print $1}'`

	  cambiar_ram=`zenity --scale --text="Selecione la cantidad de memoria RAM." --value=1024 --max-value=$TotalRam --min-value=512`
	  sed -i "s/vb\.memory = \".*/vb\.memory = \"$cambiar_ram\"/" Vagrantfile
	
	  cd "$dir_actual"
}

##  Modifica la opciones de CPUS

function Asignar_cpus(){
    clear

    select_Cpu=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))

    cd "$directorio"/$select_Cpu

	  TotalCpu=`cat /proc/cpuinfo | grep "cpu cores" | uniq | awk '{print $4}'`

	  cambiar_Cpu=`zenity --scale --text="Selecione la cantidad de CPUs." --value=1 --max-value=$TotalCpu --min-value=1`
	  sed -i "s/vb\.cpus = \".*/vb\.cpus = \"$cambiar_Cpu\"/" Vagrantfile
	
	  cd "$dir_actual"
}


## Modifica la opciones de red

function Asignar_red(){
    clear
    select_red=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))

    cd "$directorio"/$select_red


## Introducir IP
    new_ip=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
    1. DHCP
    2. IP ESTATICA
    0. SALIR"
    )

     case  $new_ip in
        1) 
                sed  -i "s/config\.vm\.network\ \"public_network\",\ ip:\ \".*/config\.vm\.network\ \"public_network\",\ type:\ \"dhcp\"/" Vagrantfile;;
                
        2) 
        
              grep "config.vm.network \"public_network\", type: \"dhcp\"" Vagrantfile > /dev/null 2>&1

              if [[ $? -eq 0 ]];then

                  cambio_ip=`zenity --entry \
                    --title="Nueva IP" \            
                    --text="Escriba la nueva IP:" \
                    --entry-text "Nuevo IP"`   

                  sed -i "s/config\.vm\.network\ \"public_network\",\ type:\ \"dhcp\"/config\.vm\.network\ \"public_network\",\ ip:\ \"$cambio_ip\"/" Vagrantfile
              fi;;
        0)
          cd "$dir_actual"
          exit 0;;
        *) 
            zenity --warning --width=450 --height=5 --title=RED --text "Opion no valida";;
     esac

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

   zenity --question  --width=450 --height=10 --text="¿Quieres conectar ahora a la maquina?"
   
   if [[ $? -eq 0 ]]; then
        vagrant ssh
   fi
   cd "$dir_actual"
}

## Seleciona el sistema operativo que usara la maquina virtual.
function Add_so(){
    opcion_add=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
    1. Ubuntu 18.04 (64/32 bits)
    2. Ubuntu 16.04 (64/32 bits)
    3. Ubuntu 14.04 (64/32 bits)
    4. Centos 7
    5. Centos 6"
    )

    if [[ $opcion_add -lt 4 ]]; then
    arquitertura=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Bits: " 1 64 2 32)
    fi
    while [[ $arquitertura -ne '32' && $arquitertura -ne '64' && $opcion_add -lt 4 ]]; do
      clear
      arquitertura=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="64 bits o 32 bits" --column=""  --column="Bits: " 1 64 2 32)
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
  
  select_drop=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":") 1 salir)
   
   if [[ $select_drop != "salir" || ! -z $select_drop ]];then
       
        zenity --question --width=450 --height=10 --text="Se va a eliminar $select_drop, ¿Deseas continuar?"
        
        if [[ $? -eq 0 ]]; then
            cd "$directorio"/$select_drop
            vagrant destroy -f > /dev/null 2>&1
            cd "$dir_actual"
	          rm -r "$directorio"/$select_drop
            cat "$directorio"/.maquinas | sed -i "/$select_drop/d" "$directorio"/.maquinas
        fi   
   fi
} 

## Edita caracteristica de la maquina virtual.
function Edit_mkv(){
    opcion_editar=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
    1. CAMBIAR NOMBRE
    2. DIRECCIÓN IP
    3. USO DE RAM
    4. USO DE CPUs
    salir"
    )
    
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
   select_ssh=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))
   
   cd "$directorio"/$select_ssh
   clear
   vagrant ssh

   if [[ $? -ne 0 ]];then
notify-send Error "No se puede estrablecer la conexion. Puede que la maquina no este en funcionamiento" -t 10000
   fi
   cd "$dir_actual"
}

## Controla las sentencia Apagar/reiniciar/suspender
function c_init(){
   comando_init=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
   1. Iniciar
   2. Apagar
   3. Reinicia
   4. Suspender
   SALIR")
   
   select_maquina_init=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))
   
   cd "$directorio"/$select_maquina_init 
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

   select_maquina_snapshot=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))

   cd "$directorio"/"$select_maquina_snapshot"

   comando_snapshot=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
   1. Listar snapshot
   2. Crear snapshot
   3. Restaura snapshot
   4. Eliminar snapshot
   SALIR")

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
    	  select_maquina_provision=$(zenity --list --radiolist --separator=' ' --title="VagrantGUI." --text="Selecione una opcion..." --column=""  --column="Nombre: " $(cat "$directorio"/.maquinas | nl | tr -d ":"))
       	cd "$directorio"/$select_maquina_provision
       	clear
        set_provision=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
       	 1. LDAP client (UBUNTU)
         2. LDAP client (CENTOS)
       	 3. Apache2 (UBUNTU)   
       	 4. REINICIAR Y APROVISIONAR
         SALIR"
        )

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
                    grep -w "ldap_cliente_centos.yml" Vagrantfile > /dev/null 2>&1

                    if [[ $? -eq 0 ]]; then
                       clear
                       echo "Ya esta aprovicionado con LDAP client"
                    else
                       sed -i 's/vb.gui = false/vb.gui = true/' Vagrantfile
        		           sed -i "/\ SHELL/a\  config.vm.provision \"ansible\" do |ansible|\n       ansible.playbook = \"/home/$(whoami)/ansible-playbook/ldap_cliente_centos.yml\"\n  end" Vagrantfile
                       clear
                       Reload_provision
                    fi;;
            3 )
                    grep -w "install_apache2.yml" Vagrantfile > /dev/null 2>&1

                    if [[ $? -eq 0 ]]; then
                       clear
                       echo "Ya esta aprovicionado con Apache2"
                    else
                       sed -i "/\ SHELL/a\  config.vm.provision \"ansible\" do |ansible|\n       ansible.playbook = \"/home/$(whoami)/ansible-playbook/install_apache2.yml\"\n  end" Vagrantfile
                       clear
                       Reload_provision
                    fi;;

    	      4 )
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
while [[ $opcion -ne 0 ]] 
clear 
do
opcion=$(zenity --width=450 --height=250 --title=VagrantGUI --entry --text=" Introduce una opción:
     1. Crear Maquina
     2. Borrar Maquina
     3. Conectar a MKV
     4. Editar Maquina
     5. Controlador de snapshot
     6. Aprovisionar MKV
     7. Iniciar/Apagar/reiniciar/suspender
     0. Salir")

    case $opcion in
    1)
        clear
        Crear_mkv
        ;;

    2)
        clear
        Rm_mkv
        ;;

    3)
        clear
        Cx_mkv
        clear;;
    4)
        clear
        Edit_mkv
        ;;
    5)
        clear
        c_snapshot
        ;;
    6)
        clear
        sync_provision
	      provision
        ;;
    7)
        clear
        c_init
        ;;

    0)
        clear
	zenity --info --width=450 --height=5 --title=VagrantGUI --text "ADIOS!!!"
	clear
	exit 0;;
    remove)
          rm -rf ~/MKV;;
    *)
        ;;

    esac

done