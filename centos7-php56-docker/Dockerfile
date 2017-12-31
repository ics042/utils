# =============================================================================
#
# CentOS-7, Apache 2.4, PHP 5.6, MYSQL
# 
# =============================================================================
FROM centos:centos7

MAINTAINER ics042 <ics0425907@gmail.com>

ARG uid=1001
ARG timezone=/usr/share/zoneinfo/Pacific/Auckland

# -----------------------------------------------------------------------------
# Import the RPM GPG keys for Repositories
# Apache + PHP
# -----------------------------------------------------------------------------
RUN yum -y install epel-release \
	&& rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm \
	&& yum -y update \
	&& yum --setopt=tsflags=nodocs -y install \
	gcc \
	gcc-c++ \
	httpd \
	mod_ssl \
	unzip \
	&& yum -y install --enablerepo=remi --enablerepo=remi-php56 \
	php \
	php-opcache \
	php-devel \
	php-mbstring \
	php-mcrypt \
	php-mysqlnd \
	php-phpunit-PHPUnit \
	php-pecl-xdebug \
	php-pecl-xhprof \
	php-mysql \
	php-pdo \
	php-soap \
	php-gd \
	php-xml \
	php-pecl-apcu \
	php-json \
	php-curl \
	php-dom \
	php-zip \
	&& ln -sf ${timezone} /etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network \
	&& chmod -R 755 /var/www/ \
	&& yum -y remove \
	gcc \
	gcc-c++ \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all \
	&& localedef -i en_GB -f UTF-8 en_GB.UTF-8

# -----------------------------------------------------------------------------
# Apache config
# -----------------------------------------------------------------------------
COPY conf/httpd.conf /etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Set ports
# -----------------------------------------------------------------------------
EXPOSE 80 443

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]