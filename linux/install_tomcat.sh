#!/bin/bash
# Source credit : https://octopus.com/docs/runbooks/runbook-examples/routine/installing-tomcat

TOMCAT_INSTALL_STARTUP=/opt/tomcat/latest/bin/startup.sh
if [[ -f $TOMCAT_INSTALL_STARTUP ]]; then
  echo "Tomcat already installed."
else

TOMCAT_USER=${tomcat_User}
TOMCAT_GROUP=${tomcat_Group}

TOMCAT_ADMIN_USER=${tomcat_AdminUser}
TOMCAT_ADMIN_PASSWORD=${tomcat_AdminPassword}

sudo apt-get update
echo "Installing Java..."
sudo apt install default-jdk -y

echo "Installing jq..."
sudo apt install jq -y

# Disable using latest version
#LATEST_TOMCAT=$(curl -s 'https://api.github.com/repos/apache/tomcat/tags' | jq -r .[].name | grep -v '-' | head -1)

echo "Creating tomcat group ..."
sudo groupadd $TOMCAT_GROUP -r

if [[ ! -d /opt/tomcat ]]; then
echo "Making tomcat folder"
sudo mkdir /opt/tomcat
fi

echo "Creating tomcat Linux user ..."
sudo useradd -r -m -d /opt/tomcat -s /bin/false -g $TOMCAT_GROUP $TOMCAT_USER

echo "Downloading Tomcat version 10..."
wget http://www.apache.org/dist/tomcat/tomcat-9/v9.0.45/bin/apache-tomcat-9.0.45.tar.gz -P /tmp

echo "Extracting Tomcat..."
sudo tar xf /tmp/apache-tomcat-9.0.45.tar.gz -C /opt/tomcat

echo "Creating symbolic link..."
sudo ln -s /opt/tomcat/apache-tomcat-9.0.45 /opt/tomcat/latest
sudo chown -RH $TOMCAT_USER: /opt/tomcat/latest
sudo sh -c 'chmod +x /opt/tomcat/latest/bin/*.sh'

echo "Creating Tomcat service file..."
cat >> tomcat.service <<EOL
[Unit]
Description=Tomcat 9 servlet container
After=network.target

[Service]
Type=forking

User=$TOMCAT_USER
Group=$TOMCAT_GROUP

Environment="JAVA_HOME=/usr/lib/jvm/default-java"
Environment="JAVA_OPTS=-Djava.security.egd=file:///dev/urandom -Djava.awt.headless=true"

Environment="CATALINA_BASE=/opt/tomcat/latest"
Environment="CATALINA_HOME=/opt/tomcat/latest"
Environment="CATALINA_PID=/opt/tomcat/latest/temp/tomcat.pid"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

ExecStart=/opt/tomcat/latest/bin/startup.sh
ExecStop=/opt/tomcat/latest/bin/shutdown.sh

[Install]
WantedBy=multi-user.target

EOL
sudo mv tomcat.service /etc/systemd/system/tomcat.service
echo "Adding management user to tomcat-users.xml..."

# Add management user
sudo cat > /opt/tomcat/latest/conf/tomcat-users.xml <<EOF
<tomcat-users xmlns="http://tomcat.apache.org/xml"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
  version="1.0">
<role rolename="manager-script"/>
<role rolename="manager-gui"/>
<user username="$TOMCAT_ADMIN_USER" password="$TOMCAT_ADMIN_PASSWORD" roles="tomcat,manager-script,manager-gui"/>
</tomcat-users>
EOF

echo "Starting Tomcat..."
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

echo "Altering firewall rules..."
sudo ufw allow 8080/tcp

fi

echo "Process complete"
