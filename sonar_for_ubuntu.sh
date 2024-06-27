#!/bin/bash

# Update and upgrade the system
sudo apt update
sudo apt upgrade -y

# Install PostgreSQL 15
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo tee /etc/apt/trusted.gpg.d/pgdg.asc &>/dev/null
sudo apt update
sudo apt-get -y install postgresql postgresql-contrib
sudo systemctl enable postgresql

# Create Database for SonarQube
sudo passwd postgres
sudo -u postgres createuser sonar
sudo -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'sonar';"
sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar;"

# Install Java 17
sudo apt install -y wget apt-transport-https
sudo mkdir -p /etc/apt/keyrings
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update
sudo apt install -y temurin-17-jdk
sudo update-alternatives --config java
java --version

# Increase Limits
echo "sonarqube   -   nofile   65536" | sudo tee -a /etc/security/limits.conf
echo "sonarqube   -   nproc    4096" | sudo tee -a /etc/security/limits.conf
echo "vm.max_map_count = 262144" | sudo tee -a /etc/sysctl.conf

# Reboot to set the new limits
#sudo reboot

# After reboot, continue with the script

# Install SonarQube
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.0.65466.zip
sudo apt install -y unzip
sudo unzip sonarqube-9.9.0.65466.zip -d /opt
sudo mv /opt/sonarqube-9.9.0.65466 /opt/sonarqube
sudo groupadd sonar
sudo useradd -c "user to run SonarQube" -d /opt/sonarqube -g sonar sonar
sudo chown sonar:sonar /opt/sonarqube -R

# Update SonarQube properties with DB credentials
sudo sed -i '/sonar.jdbc.username=/c\sonar.jdbc.username=sonar' /opt/sonarqube/conf/sonar.properties
sudo sed -i '/sonar.jdbc.password=/c\sonar.jdbc.password=sonar' /opt/sonarqube/conf/sonar.properties
echo "sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube" | sudo tee -a /opt/sonarqube/conf/sonar.properties

# Create service for SonarQube
sudo bash -c 'cat << EOF > /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking

ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop

User=sonar
Group=sonar
Restart=always

LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF'

# Start SonarQube and Enable service
sudo systemctl start sonar
sudo systemctl enable sonar
sudo systemctl status sonar
sudo tail -f /opt/sonarqube/logs/sonar.log
