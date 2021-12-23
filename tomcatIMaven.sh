#!/bin/bash

read -p "Input name user: " USERNAME

sudo apt-get update -y


#Install MAVEN

sudo apt install openjdk-8-jdk -y
java -version
wget https://archive.apache.org/dist/maven/maven-3/3.5.3/binaries/apache-maven-3.5.3-bin.tar.gz
sudo tar -xvf apache-maven-3.5.3-bin.tar.gz
sudo mkdir /opt/maven
sudo mv /home/$USERNAME/apache-maven-3.5.3/* /opt/maven
sudo cat >> /home/$USERNAME/.bashrc << EOF
JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
M2_HOME=/opt/maven
MAVEN_HOME=/opt/maven
PATH=/opt/maven/bin:${PATH}
EOF
source /home/$USERNAME/.bashrc
mvn -version

#Instal Tomcat and setap

sudo mkdir /opt/tomcat
sudo groupadd tomcat
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.56/bin/apache-tomcat-9.0.56.tar.gz
sudo tar -xvf apache-tomcat-9.0.56.tar.gz
sudo mv /home/$USERNAME/apache-tomcat-9.0.56/* /opt/tomcat/
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r /opt/tomcat/conf
sudo chmod g+x /opt/tomcat/conf
sudo chown tomcat:tomcat /opt/tomcat/webapps/ /opt/tomcat/work/ /opt/tomcat/temp/ /opt/tomcat/logs/
sudo systemctl daemon-reload

sudo cat > /etc/systemd/system/tomcat.service << EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload


sudo cat > /opt/tomcat/conf/tomcat-users.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>

<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="tomcat"/>
<role rolename="manager-gui"/>
<user username="admin" password="password" roles="manager-gui,admin-gui"/>
</tomcat-users>
EOF


sudo cat > /opt/tomcat/webapps/host-manager/META-INF/context.xml << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor" sameSiteCookies="strict" />
  <!--<Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOF

sudo cp /opt/tomcat/webapps/host-manager/META-INF/context.xml  /opt/tomcat/webapps/manager/META-INF/context.xml

sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat
sudo ufw allow 8080
sudo systemctl restart tomcat

#clear file
sudo rm -rf /home/$USERNAME/apach-*

#Info about setup

sudo systemctl status tomcat
echo ""
echo "______________________________________________________"
echo "Open in web browser http://server_domain_or_IP:8080"
echo "Login for APPManager: username=admin password=password"
echo "______________________________________________________"
echo ""
echo "If don't work Maven? Than comlite this comand: source ~/.bashrc"
