#!/bin/bash
set -x
set -e

cd ~/project/terraform/

touch terraform.tfvars 
echo "my_ip = \"$(curl -s ifconfig.me)/32\"" > terraform.tfvars
terraform validate
terraform apply -auto-approve

#sudo apt install -y jq

##get output variables
proxy_public_ip=$(terraform output -raw proxy_eip)
proxy_private_ip=$(terraform output -raw proxy-private-ip)
ips=$(terraform output -json web-server-private-ips | jq -r '.[]')
web_server_private_ips=()
while read -r ip; do
  web_server_private_ips+=("$ip")
done <<< "$ips"

if [[ -z "$proxy_public_ip" ]]; then
  echo "Failed to get proxy_public_ip"; exit 1;
fi

echo -e "\n\e[32m✔ Varibles sucessfully gotten from output\e[0m\n"
echo "proxy-public-ip: ${proxy_public_ip}"
echo "proxy-private-ip ${proxy_private_ip} \n"
echo "web-server-private-ip-1: ${web_server_private_ips[0]}"
echo "web-server-private-ip-2: ${web_server_private_ips[1]}"
echo "web-server-private-ip-3: ${web_server_private_ips[2]}"

cd ~/project/ansible
rm -f inventory.ini
rm -f playbook.yml
rm -f ansible2.cfg

touch inventory.ini
cat << EOF > inventory.ini
[proxyservers]
proxy
[webservers]
web1 server_id=1
web2 server_id=2
web3 server_id=3
EOF

cd ~/.ssh/
rm -f ~/.ssh/config
touch config
cat << EOF > config
Host proxy
    Hostname ${proxy_public_ip}
    User ubuntu
    IdentityFile ~/.ssh/meu-par-de-chaves.pem
    IdentitiesOnly yes
    StrictHostKeyChecking no

Host web1
    Hostname ${web_server_private_ips[0]}
    User ubuntu
    IdentityFile ~/.ssh/meu-par-de-chaves.pem
    ProxyJump proxy
    StrictHostKeyChecking no

Host web2
	Hostname ${web_server_private_ips[1]}
	User ubuntu
	IdentityFile ~/.ssh/meu-par-de-chaves.pem
	ProxyJump proxy
    	StrictHostKeyChecking no

Host web3
	Hostname ${web_server_private_ips[2]}
	User ubuntu
	IdentityFile ~/.ssh/meu-par-de-chaves.pem
    ProxyJump proxy
    StrictHostKeyChecking no
EOF


cd ~/project/ansible
touch playbook.yml
cat << EOF > playbook.yml
- name: set up nginx on proxy
  hosts: proxy
  become: yes
  tasks:
    - name: run apt update
      apt:
        update_cache: yes
        cache_valid_time: 3600
    - name: install nginx
      apt:
        name: nginx
        state: present
    - name: configure nginx
      copy:
        dest: /etc/nginx/nginx.conf
        content: |
           user www-data;
           worker_processes auto;
           pid /run/nginx.pid;
           error_log /var/log/nginx/error.log;
           include /etc/nginx/modules-enabled/*.conf;
           events {
            worker_connections 768;
            multi_accept on;
           }
           http {
           upstream backend {
            server ${web_server_private_ips[0]};
            server ${web_server_private_ips[1]};
            server ${web_server_private_ips[2]};
           }
           server {
            location / {
             proxy_pass http://backend;
            }
           }
            include /etc/nginx/mime.types;
            default_type application/octet-stream;
            access_log /var/log/nginx/access.log;
            include /etc/nginx/conf.d/*.conf;
            include /etc/nginx/sites-enabled/*;
           }
    - name: erase nginx file
      copy:
        dest: /etc/nginx/sites-available/default
        content: ""
    - name: stop nginx
      service:
        name: nginx
        state: stopped
    - name: start nginx
      service:
        name: nginx
        state: started


- name: set up http python server on webservers
  hosts: webservers
  become: true
  tasks:
    - name: Create web root directory
      file:
        path: /opt/simple-web
        state: directory

    - name: Create test index.html
      copy:
        dest: /opt/simple-web/index.html
        content: "<h1>Web Server {{server_id}}</h1>"

    - name: start python http server
      shell: nohup python3 -m http.server 80 --directory /opt/simple-web &>/dev/null &
      args:
        executable: /bin/bash
      async: 0
      poll: 0

    - name: Allow port 80
      ufw:
        rule: allow
        port: '80'
        proto: tcp
      when: ansible_facts.os_family == 'Debian'


EOF



ansible-playbook -i inventory.ini playbook.yml
