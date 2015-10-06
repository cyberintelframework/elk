#!/bin/sh

echo "*****     CIF (Cyber Intelligence Framework)			*****"
echo "*****                                             		*****"
echo "*****     Author: Gijs Rijnders					*****"
echo "*****                                             		*****"
echo "*****     Log server installation script				*****"
echo "*****     This script will install the Logstash,			*****"
echo "*****     ElasticSearch and Kibana components.			*****"
echo ""

# Check if the script is ran with root permissions

if [[ $UID != 0 ]]; then
    echo "Please run this script with sudo:"
    echo "sudo $0 $*"
    exit 1
fi

# Install Java 8

echo "*****     Installing Java 8...                    		*****"
cd /opt

# Download Java 8u60 (Update these lines if a newer Java version/update is released!)

wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u60-b27/jdk-8u60-linux-x64.tar.gz"
tar xzf jdk-8u60-linux-x64.tar.gz
rm -f jdk-8u60-linux-x64.tar.gz
cd /opt/jdk1.8.0_60/

# Install Java as alternative. It may have to be selected as primary manually

alternatives --install /usr/bin/java java /opt/jdk1.8.0_60/bin/java 2
alternatives --install /usr/bin/jar jar /opt/jdk1.8.0_60/bin/jar 2
alternatives --install /usr/bin/javac javac /opt/jdk1.8.0_60/bin/javac 2
alternatives --set jar /opt/jdk1.8.0_60/bin/jar
alternatives --set javac /opt/jdk1.8.0_60/bin/javac

# Check if the Java environment variables are already set

if [ $(grep -c 'jdk1.8' /etc/environment) -ne 0 ]
then
	echo "*****	The environment variables are already set!	*****"
else

	# Set Java environment variables accordingly
	
	echo "JAVA_HOME=/opt/jdk1.8.0_60" >> /etc/environment
	echo "JRE_HOME=/opt/jdk1.8.0_60/jre" >> /etc/environment
	echo "PATH=$PATH:/opt/jdk1.8.0_60/bin:/opt/jdk1.8.0_60/jre/bin" >> /etc/environment
fi
	
echo "*****	Installing ElasticSearch...				*****"

# Add the ElasticSearch repository and install the packages

sudo rpm --import http://packages.elasticsearch.org/GPG-KEY-elasticsearch

# Check if the repository descriptor exists

if [ -f "/etc/yum.repos.d/elasticsearch.repo" ]
then
	rm -f /etc/yum.repos.d/elasticsearch.repo
fi

# (Re)create the repository descriptor

touch /etc/yum.repos.d/elasticsearch.repo
printf '%s\n%s\n%s\n%s\n%s\n%s' '[elasticsearch-1.7]' 'name=Elasticsearch repository for 1.7.x packages' 'baseurl=http://packages.elasticsearch.org/elasticsearch/1.7/centos' 'gpgcheck=1' 'gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch' 'enabled=1' >> /etc/yum.repos.d/elasticsearch.repo
yum -y install elasticsearch

# Enable and start ElasticSearch using SystemCtl

systemctl start elasticsearch
systemctl enable elasticsearch

echo "*****	Installing Kibana...					*****"

# Check whether Kibana4 is already installed (in case of an error in a previous execution of this script)

if [ $(systemctl status kibana4 | grep -c not-found) = 1 ]
then
	# Download and unpack Kibana4
	
	cd ~; wget https://download.elasticsearch.org/kibana/kibana/kibana-4.1.2-linux-x64.tar.gz
	tar xf kibana-*.tar.gz
	rm -f kibana-*.tar.gz
	mkdir -p /opt/kibana
	cp -R ~/kibana-4*/* /opt/kibana/
	touch /etc/systemd/system/kibana4.service

	# Enable and start Kibana4 as a service
	
	printf '%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s' '[Service]' 'ExecStart=/opt/kibana/bin/kibana' 'Restart=always' 'StandardOutput=syslog' 'StandardError=syslog' 'SyslogIdentifier=kibana4' 'User=root' 'Group=root' 'Environment=NODE_ENV=production' '[Install]' 'WantedBy=multi-user.target' >> /etc/systemd/system/kibana4.service
	systemctl start kibana4
	systemctl enable kibana4
else
	echo "*****	Kibana4 is already installed, nothing to do!	*****"
fi

echo "*****	Installing Logstash...					*****"

# Add the Logstash repository and install the packages

# Check if the Logstash repository descriptor exists

if [ -f "/etc/yum.repos.d/logstash.repo" ]
then
	rm -f /etc/yum.repos.d/logstash.repo
fi

# (Re)create the repository descriptor

touch /etc/yum.repos.d/logstash.repo
printf '%s\n%s\n%s\n%s\n%s\n%s' '[logstash-1.5]' 'name=logstash repository for 1.5.x packages' 'baseurl=http://packages.elasticsearch.org/logstash/1.5/centos' 'gpgcheck=1' 'gpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch' 'enabled=1' >> /etc/yum.repos.d/logstash.repo
yum -y install logstash

# Enable and start the Logstash service

systemctl start logstash

# Display notices for the user at the end of the installation script

echo ""
echo "*****     A new version of java has been installed on the system.	*****"
echo "*****     If you have multiple versions of Java installed, use	*****"
echo "*****     the 'alternatives --config java' command to manually	*****"
echo "*****     select the latest one to be active.                     *****"
echo "*****                                                             *****"
echo "*****	For extra security, change the network.host setting	*****"
echo "*****	of ElasticSearch. Change the line 'network.host:<ip>'	*****"
echo "*****	into 'network.host: localhost'. Do this in the file:	*****"
echo "*****	/etc/elasticsearch/elasticsearch.yml and restart	*****"
echo "*****	the ElasticSearch service.				*****"
echo "*****								*****"
echo "*****     CIF Logserver components have been installed!           *****"
