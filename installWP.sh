#!/bin/bash
# me@aroel.net
# Please edit the variables to meet your requirements

green=`tput setaf 2`
yellow=`tput setaf 3`
cyan=`tput setaf 6`
reset=`tput sgr0`


WEBDIR="/var/www"
SITESDIR="/var/www/html"

NGINX_AVAILABLE="/etc/nginx/sites-available"
NGINX_ENABLED="/etc/nginx/sites-enabled"
FPM_SOCKET="/run/php/php7.0-fpm.sock"
WP_CLI="/usr/bin/wp-cli"
OWNER=www-data
GROUP=www-data

#Create Database

echo "Creating a database for your domain..........."
echo "${cyan}Enter your domain name so I can create a database for it${reset}"
read domainname
echo ""

random=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
DB_PASS=`pwgen -cnBv1 10`
SHORTDBNAME=`echo $domainname | cut -c1-5`
dbname=${SHORTDBNAME}_$random
dblogin=$dbname
ADMIN_EMAIL=admin@$domainname
ADMIN_PASS=`pwgen -cnBv1 15`

echo "${yellow}Database $dbname.${reset} has been created"
echo ""

mysql -e "CREATE DATABASE ${dbname};"
mysql -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbname}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "FLUSH PRIVILEGES;"

sleep 1

echo "#############################"
echo "${green}Domain name${reset}: $domainname"
echo "${green}DB Name${reset}: $dbname"
echo "${green}DB User${reset}: $dbname"
echo "${green}DB Password${reset}: $DB_PASS"
echo "#############################"
echo ""

sleep 1

#Create admin login
echo "${cyan}Please type your desired administator login name...........${reset}"
read ADMIN_LOGIN
echo ""
echo "${yellow}Your administrator login is $ADMIN_LOGIN.....${reset}"
echo ""
sleep 1

#Create website directory
echo "${yellow}Creating website directory...........${reset}"
echo ""
sleep 1

        if ! [ -d ${WEBDIR}/tmp ]; then
                mkdir ${WEBDIR}/tmp
                chown -R ${OWNER}:${GROUP} ${WEBDIR}/tmp
        fi
        if ! [ -d ${SITESDIR} ]; then
                mkdir -p ${SITESDIR}
                chown -R ${OWNER}:${GROUP} ${SITESDIR}
        fi
        mkdir -p ${SITESDIR}/${domainname}/{public_html,logs}
        chown -R ${OWNER}:${GROUP} ${SITESDIR}/${domainname}
        chmod 0750 ${SITESDIR}/${domainname}
	echo ""
        echo -e "${yellow}Website directory ${SITESDIR}/${domainname}/public_html has been created${reset}"
	echo ""
sleep 1

#Install Latest WordPress
echo "${yellow}Installing WordPress...........${reset}"
echo ""
        echo "Self update"
        ${WP_CLI} cli update --allow-root
        echo "Downloading wordpress Core"
        ${WP_CLI} core download --path=${SITESDIR}/${domainname}/public_html --locale=en_US --allow-root
        echo "Creating wp-config file"
        ${WP_CLI} config create --path=${SITESDIR}/${domainname}/public_html --dbname=${dbname} --dbuser=${dblogin} --dbpass=${DB_PASS} --dbhost=localhost --dbcharset=utf8mb4 --locale=en_US --allow-root
        echo "Installing WordPress now"
        ${WP_CLI} core install --path=${SITESDIR}/${domainname}/public_html --url=${domainname} --title="My WordPress site" --admin_user=${ADMIN_LOGIN} --admin_password=${ADMIN_PASS} --admin_email=${ADMIN_EMAIL} --allow-root
        chown -R ${OWNER}:${GROUP} ${SITESDIR}/${domainname}

sleep 1

#Create nginx server block

echo "${yellow}Creating nginx server block for domain $domainname${reset}"
echo ""
        nginxconfig="server {
    listen 80;
    root $SITESDIR/$domainname/public_html;
    index index.php index.html index.htm;
    server_name $domainname www.$domainname;
    access_log $SITESDIR/$domainname/logs/access.log;
    error_log $SITESDIR/$domainname/logs/error.log;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location ~* \.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }
    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(.*)\$;
        fastcgi_pass unix:$FPM_SOCKET;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_ignore_client_abort on;
        fastcgi_param SERVER_NAME \$http_host;
    }
        }"
        touch ${NGINX_AVAILABLE}/${domainname}.conf
        echo "$nginxconfig" >> ${NGINX_AVAILABLE}/${domainname}.conf
        ln -s ${NGINX_AVAILABLE}/${domainname}.conf ${NGINX_ENABLED}/${domainname}.conf
        echo "Config generated"
        echo "Check config and restart nginx"
        nginx -t && systemctl restart nginx
        echo ""
        echo ""


sleep 1

#Installation completed
echo "########################################"
        echo -e "##########${cyan}Installation Details${reset}##########"
        echo "########################################"
        echo ""
        echo "${green}Installed Wordpress${reset}: `${WP_CLI} core version --path=${SITESDIR}/${domainname}/public_html --allow-root`"
        echo "${green}DOMAIN${reset}: $domainname"
        echo "${green}WP ADMIN LOGIN${reset}: $ADMIN_LOGIN"
        echo "${green}WP ADMIN PASS${reset}: $ADMIN_PASS"
        echo ""
	echo "${green}Thank you for using this script${reset}"



