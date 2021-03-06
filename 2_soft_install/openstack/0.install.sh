#!/bin/sh

init_iptables(){
        iptables -L
        iptables -F
        service iptables save
        systemctl  stop firewalld.service
        systemctl disable firewalld.service 
}

init_selinux(){
        sed -i  's/SELINUX=enforcing/SELINUX=disable/' /etc/sysconfig/selinux
         sed -i  's/SELINUX=enforcing/SELINUX=disable/'  /etc/selinux/config
        getenforce
        setenforce  0
        getenforce
}

init_ldconf(){
        grep -q '/usr/local/lib' /etc/ld.so.conf       || sed '$a /usr/local/lib ' /etc/ld.so.conf
        grep -q '/usr/lib64/' /etc/ld.so.conf          || sed '$a /usr/lib64/'  /etc/ld.so.conf
        for app in $(ls /usr/local)
        do
        [ -d /usr/local/$app/lib ] || continue
        grep  "/usr/local/$app/lib"  /etc/ld.so.conf.d/luomgf.conf  && continue
        echo "/usr/local/$app/lib" >> /etc/ld.so.conf.d/luomgf.conf

        done
        ldconfig  -v
}

init_timesync(){
	yum install chrony  -y
	systemctl enable chronyd.service
	systemctl start chronyd.service
}

init_hosts(){

grep '127.0.0.1'  /etc/hosts  || sed -i '$a	 127.0.0.1    localhost '   /etc/hosts
grep '::1'        /etc/hosts  || sed -i '$a      ::1          localhost '   /etc/hosts
grep '10.20.0.10' /etc/hosts  || sed -i '$a      10.20.0.10   controller0'  /etc/hosts
grep '10.20.0.20' /etc/hosts  || sed -i '$a      10.20.0.20   network0'     /etc/hosts
grep '10.20.0.30' /etc/hosts  || sed -i '$a      10.20.0.30   compute0'     /etc/hosts


#vi /etc/sysconfig/network
#HOSTNAME=controller0
}

install_openstack(){

	yum install centos-release-openstack-pike	-y
	yum upgrade					-y
	yum install python-openstackclient		-y
	yum install openstack-selinux			-y




}

install_mariadb(){

	 yum -y install mariadb mariadb-server python2-PyMySQL

cat > /etc/my.cnf.d/openstack.cnf<<'eof'
[mysqld]
bind-address = 10.20.0.10

default-storage-engine = innodb
innodb_file_per_table = on
max_connections = 4096
collation-server = utf8_general_ci
character-set-server = utf8
eof
systemctl enable mariadb.service
systemctl start  mariadb.service
mysql_secure_installation

}
        init_iptables
        init_selinux
        init_ldconf
	init_timesync
	init_hosts

	install_openstack
	
