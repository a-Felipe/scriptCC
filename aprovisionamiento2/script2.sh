  # sudo snap install lxd
  # sudo gpasswd -a vagrant lxd

#    cat <<EOF | lxd init --preseed
# config:
#   core.https_address: 192.168.100.7:8443
#   core.trust_password: vagrant
# networks:
# - config:
#     bridge.mode: fan
#     fan.underlay_subnet: 192.168.100.0/24
#   description: ""
#   name: lxdfan0
#   type: ""
# storage_pools:
# - config: {}
#   description: ""
#   name: local
#   driver: dir
# profiles:
# - config: {}
#   description: ""
#   devices:
#     eth0:
#       name: eth0
#       network: lxdfan0
#       type: nic
#     root:
#       path: /
#       pool: local
#       type: disk
#   name: default
# cluster:
#   server_name: balanceador
#   enabled: true
#   member_config: []
#   cluster_address: ""
#   cluster_certificate: ""
#   server_address: ""
#   cluster_password: ""
# EOF
  
  echo "Instalar el servidor de balancedor"
  lxc init ubuntu:20.04 balanceador --target balanceador < /dev/null

  echo "Levantar el servidor de balanceador"
  lxc start balanceador
 

  echo "Crear archivo de configuracion haproxy"
  sudo touch haproxy.cfg
  sudo echo "global
  log /dev/log    local0
  log /dev/log    local1 notice
  chroot /var/lib/haproxy
  stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
  stats timeout 30s
  user haproxy
  group haproxy
  daemon

     # Default SSL material locations
       ca-base /etc/ssl/certs
       crt-base /etc/ssl/private

        # See: https://ssl-config.mozilla.org/#server=haproxy&server-version=2.0.3&config=intermediate
        ssl-default-bind-ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        ssl-default-bind-ciphersuites TLS_AES_128_GCM_SHA256:TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
        ssl-default-bind-options ssl-min-ver TLSv1.2 no-tls-tickets

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        timeout connect 5000
        timeout client  50000
        timeout server  50000
        errorfile 400 /etc/haproxy/errors/400.http
        errorfile 403 /etc/haproxy/errors/403.http
        errorfile 408 /etc/haproxy/errors/408.http
        errorfile 500 /etc/haproxy/errors/500.http
        errorfile 502 /etc/haproxy/errors/502.http
        errorfile 503 /etc/haproxy/errors/503.http
        errorfile 504 /etc/haproxy/errors/504.http

frontend http
  bind *:80

  acl servidores_muertos nbsrv(web_backend) lt 2
  use_backend web_backup if servidores_muertos

  default_backend web_backend
   
backend web_backend
  mode http
  balance roundrobin
  stats enable
  stats auth stranger:stranger
  stats uri /haproxy?stats

  server web1 240.8.0.60:80 check
  server web2 240.9.0.62:80 check 

backend web_backup
  mode http
  balance roundrobin
  stats enable
  stats auth stranger:stranger
  stats uri /haproxy?stats

  option allbackups
  server webackup1 240.8.0.61 check backup
  server webackup2 240.9.0.63 check backup">> haproxy.cfg
  

  sleep 40s

  sudo lxc exec balanceador -- apt install haproxy -y
  sudo lxc exec balanceador -- systemctl enable haproxy
  sudo lxc file push haproxy.cfg balanceador/etc/haproxy/haproxy.cfg
  sudo lxc exec balanceador -- systemctl start haproxy
  lxc config device add balanceador http proxy listen=tcp:0.0.0.0:9080 connect=tcp:127.0.0.1:80

  sleep 40s 

  echo"Crear el mensaje de error"
  sudo mkdir error
  cd error
  sudo touch 503.http
  sudo echo "<!DOCTYPE html>
  <html>
  <body>
  <center><h1>No tenemos servicios! Lo sentimos</h1></center>
  </body>
  </html>" >> 503.http
  lxc file push 503.http balanceador/etc/haproxy/errors
  cd ..

  sleep 15s
  sudo lxc exec balanceador -- systemctl restart haproxy


  
 # sed ':a;N;$!ba;s/\n/\n\n/g' /var/snap/lxd/common/lxd/server.crt