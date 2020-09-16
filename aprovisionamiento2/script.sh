#!/bin/bash
#    sudo snap install lxd
#    sudo gpasswd -a vagrant lxd
#    

#    cat <<EOF | lxd init --preseed
# config: {}
# networks: []
# storage_pools: []
# profiles: []
# cluster:
#   server_name: web1
#   enabled: true
#   member_config:
#   - entity: storage-pool
#     name: local
#     key: source
#     value: ""
#     description: '"source" property for storage pool "local"'
#   cluster_address: 192.168.100.7:8443
#   cluster_certificate: |
#     -----BEGIN CERTIFICATE-----

#    MIICEjCCAZigAwIBAgIQR8HOUdy8fdOWKPsQOnpwbTAKBggqhkjOPQQDAzA5MRww
#    GgYDVQQKExNsaW51eGNvbnRhaW5lcnMub3JnMRkwFwYDVQQDDBByb290QGJhbGFu
#    Y2VhZG9yMB4XDTIwMDkxNTE4MDgxOVoXDTMwMDkxMzE4MDgxOVowOTEcMBoGA1UE
#    ChMTbGludXhjb250YWluZXJzLm9yZzEZMBcGA1UEAwwQcm9vdEBiYWxhbmNlYWRv
#    cjB2MBAGByqGSM49AgEGBSuBBAAiA2IABD5/0MKt9mkatZOl2Yo8u4tjGLTDhkwK
#    fiwNduaf0KQVosiEZnyNhrJnmwAgGTIJQcAbzkMgVThc5rljqj+q4eKHuclVkUwG
#    g9e4jlcI8EODUTwQUcW/k71hD+W78+jN6aNlMGMwDgYDVR0PAQH/BAQDAgWgMBMG
#    A1UdJQQMMAoGCCsGAQUFBwMBMAwGA1UdEwEB/wQCMAAwLgYDVR0RBCcwJYILYmFs
#    YW5jZWFkb3KHBH8AAAGHEAAAAAAAAAAAAAAAAAAAAAEwCgYIKoZIzj0EAwMDaAAw
#    ZQIxAIlnO8dpsmGItql3aWhivXTYEPuL2fJoWzyr5GZYGLxvyG39vOjXeQ9ZUDG4
#    MB6a9QIwbUiG3e5V6kBb3V6sP/o5bLf4zJG23D02pqyLkI03i0+LgMRMCV3tPKz6
#    pCifkJHu

#    ----- END CERTIFICATE-----
#   server_address: 192.168.100.8:8443
#   cluster_password: vagrant
# EOF
   
 # Creación de los contenedores
 sleep 30s

   echo "Instalar el servidor de ubuntu"
   lxc init ubuntu:20.04 web1 --target web1 < /dev/null

   echo "Levantar el servidor de web1"
   lxc start web1

   echo "Instalar el servidor de ubuntu para backup"
   lxc init ubuntu:20.04 webackup1 --target web1 < /dev/null

   echo "Levantar el servidor de webackup1"
   lxc start webackup1

   sleep 30s

   sudo lxc exec web1 -- apt-get install apache2 -y
   sudo lxc exec web1 -- apt-get systemctl enable apache2
   sudo lxc exec web1 -- apt-get systemctl start apache2

   sleep 30s

   sudo lxc exec webackup1 -- apt-get install apache2 -y
   sudo lxc exec webackup1 -- apt-get systemctl enable apache2
   sudo lxc exec webackup1 -- apt-get systemctl start apache2 

   sleep 30s   
 # Configuracion de los archivos de html

  echo "Crear el index para web1"
  sudo mkdir web
  cd web
  sudo touch index.html
  sudo echo "<!DOCTYPE html>
  <html>
  <body>
  <center><h1>Página de WEB1</h1></center>
  </body>
  </html>" >> index.html
  lxc file push index.html web1/var/www/html/index.html
  cd ..
   
  
  echo "Crear index para backup1"
  sudo mkdir backup
  cd backup
  sudo touch index.html
  sudo echo "<!DOCTYPE html>
  <html>
  <body>
  <center><h1>Página de Backup1</h1></center>
  </body>
  </html>" >> index.html
  lxc file push index.html webackup1/var/www/html/index.html
   cd ..
 
   sleep 30s

   lxc stop web1
   lxc network attach lxdfan0 web1 eth0
   lxc config device set web1 eth0 ipv4.address 240.8.0.60
   lxc start web1

   sleep 30s

   lxc stop webackup1
   lxc network attach lxdfan0 webackup1 eth0
   lxc config device set webackup1 eth0 ipv4.address 240.8.0.61
   lxc start webackup1