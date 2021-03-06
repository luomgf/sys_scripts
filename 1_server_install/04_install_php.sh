#!/bin/bash

VER=${1-"5.6.20"}
PKGNAME="php-$VER.tar.gz"
PKGDIR=${PKGNAME%.tar.gz}
PREFIX="/opt/php/$PKGDIR"
SRCDIR=~/sys_scripts/1_server_install
PKGHOME=~/pkg/tmp/$PKGDIR

install-yum(){
	yum install  -y  libxml2  libxml2-devel m4 autoconf  \
	libcurl-devel  libjpeg* libpng*  
}

install-php(){

    export  PATH=$PREFIX/bin:$PATH

    [ -f $PKGNAME ] || { 
    echo "not exists "
    exit 127 
    }
	cp $PKGNAME ./tmp
	cd  tmp

    [ -d "php-$VER" ] || tar -zxvf  $PKGNAME
    mkdir  -p $PREFIX 

    cd  php-$VER  || exit 127
   #./configure clean
   ./configure  --prefix=$PREFIX \
       --with-apxs2=/usr/local/httpd/bin/apxs \
       --enable-fpm  \
      --disable-fileinfo       # mem < 1g
  # make clean
    make  &&  make install
   [ -L /usr/local/php ] && rm  -rf  /usr/local/php
   [ -L /etc/php ] &&  rm  -rf  /etc/php
   ln  -s  $PREFIX  /usr/local/php

    cp $SRCDIR/php/init.d/php-fpm   /etc/rc.d/init.d/php-fpm
    chmod 755  /etc/rc.d/init.d/php-fpm
    chkconfig  --add php-fpm
   cp  $SRCDIR/php/php.ini       $PREFIX/lib/
   cp  $SRCDIR/php/php-fpm.conf  $PREFIX/etc/
    grep $PREFIX /etc/profile >/dev/null ||  sed  -i '$a export  PATH='$PREFIX'/bin:$PATH' /etc/profile

   [ -d  /etc/php ] ||  mkdir  -p  /etc/php
   ln  -s  $PREFIX/etc/php-fpm.conf /etc/php/php-fpm.conf
   ln  -s  $PREFIX/lib/php.ini /etc/php/php.ini
}
module_install(){
    #/usr/local/php/bin/phpize
#./configure --with-php-config=/usr/local/php/bin/php-config  --with-pdo-mysql=/usr/local/mysql/
# --with-curl=/usr/include/curl
#--with-pdo-pgsql=/usr/local/pgsql/bin
#--with-pgsql=/usr/local/pgsql/bin
#extension=mysql.so
#--with-freetype-dir=/usr/ --enable-gd-native-ttf   # gd module add option

#gd
#yum install -y  libwebp  libwebp-dev*  libjpeg  libjpeg-dev* libpng libpng-dev* libz libz-dev* libXpm libXpm-dev*
#/usr/local/php/bin/phpize
#./configure    	--with-php-config=/usr/local/php/bin/php-config    \
#	--with-freetype-dir=/usr/                   \
#  	--with-webp-dir=/usr/                  \
#  	--with-jpeg-dir=/usr/                  \
#  	--with-png-dir=/usr/                     \
#  	--with-zlib-dir=/usr/                    \
#  	--with-xpm-dir=/usr/                  \
#  	--enable-gd-native-ttf     
         
	cd $PKGHOME/ext
	for module in $(ls -F |grep "/$")
	do	
		cd $PKGHOME/ext/$module || exit
		/usr/local/php/bin/phpize
		./configure --with-php-config=/usr/local/php/bin/php-config
		make  && make install 
		echo module: $module  install success
	done

        cd /usr/local/php//lib/php/extensions/no-debug-zts-*
	for module in $(ls  *.so)
	do	
	       echo $module
		grep  -q $module /usr/local/php/lib/php.ini || sed  -i   '$a extension='$module''   /usr/local/php/lib/php.ini 
	done
}
install-php-fpm(){
echo ""
}
	mkdir  -p ~/pkg/tmp
	cd ~/pkg
	install-yum	
	install-php
	module_install
	
