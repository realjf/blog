---
title: "MySQL 5.7 源码安装"
date: 2020-04-28T14:31:48+08:00
keywords: ["sql"]
categories: ["mysql"]
tags: ["sql"]
series: [""]
draft: false
toc: false
related:
  threshold: 80
  includeNewer: false
  toLower: false
  indices:
  - name: keywords
    weight: 100
  - name: tags
    weight: 90
  - name: categories
    weight: 50
  - name: date
    weight: 10
---

#### 源码安装
源码下载地址:[http://cdn.mysql.com/Downloads/MySQL-5.7/mysql-5.7.15.tar.gz](http://cdn.mysql.com/Downloads/MySQL-5.7/mysql-5.7.15.tar.gz)

先检查已有的mysql
```
rpm -qa | grep mysql
rpm -e mysql-libs-5.1.73-3.el6_5.x86_64 --nodeps
```

#### 1. 安装依赖的包
由于从mysql5.5开始弃用了常规的configure编译方法，所以需要下载cmake编译器、boost库、ncurses库和gnu分析器生成器bison这4种工具。
```
yum -y install make gcc-c++  ncurses-devel
```
安装cmake
```
wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz
tar zxvf cmake-3.6.2.tar.gz
cd cmake-3.6.2
./configure
make && make install
```
安装bison
```
wget -c http://git.typecodes.com/libs/ccpp/bison-3.0.tar.gz
tar zxvf bison-3.0.tar.gz && cd bison-3.0/ && ./configure
make && make install
```

安装boost
```
wget http://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz
tar zxvf boost_1_59_0.tar.gz
cd boost_1_59_0
./bootstrap.sh
./b2 stage threading=multi link=shared
./b2 install threading=multi link=shared
```
或者
```
wget http://sourceforge.mirrorservice.org/b/bo/boost/boost/1.59.0/boost_1_59_0.tar.bz2
tar jxvf boost_1_59_0.tar.bz2
// 其他的同上
```
>附：卸载boost很简单，只需要删除/usr/local/include目录下和/usr/local/lib目录下有关boost的库文件就可以

#### 2. 下载编译安装mysql
```
mkdir /usr/local/mysql
mkdir /usr/local/mysql/data

wget http://cdn.mysql.com/Downloads/MySQL-5.7/mysql-5.7.15.tar.gz
tar zxvf mysql-5.7.15.tar.gz
cd mysql-5.7.15

// 编译安装
cmake \
-DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
-DMYSQL_DATADIR=/usr/local/mysql/data \
-DSYSCONFDIR=/etc \
-DWITH_MYISAM_STORAGE_ENGINE=1 \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_MEMORY_STORAGE_ENGINE=1 \
-DWITH_READLINE=1 \
-DMYSQL_UNIX_ADDR=/var/lib/mysql/mysql.sock \
-DMYSQL_TCP_PORT=3306 \
-DENABLED_LOCAL_INFILE=1 \
-DENABLED_DOWNLOADS=1 \
-DWITH_PARTITION_STORAGE_ENGINE=1 \
-DEXTRA_CHARSETS=all \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DMYSQL_USER=mysql \
-DWITH_DEBUG=0 \
-DMYSQL_MAINTAINER_MODE=0 \
-DWITH_SSL:STRING=bundled \
-DWITH_ZLIB:STRING=bundled

make && make install
```

>编译的参数可以参考[http://dev.mysql.com/doc/refman/5.5/en/source-configuration-options.html](http://dev.mysql.com/doc/refman/5.5/en/source-configuration-options.html)

#### 3. 设置权限
使用下面的命令查看是否有mysql用户及用户组
```
cat /etc/passwd // 查看用户列表
cat /etc/group // 查看用户组列表
```
如果没有就创建
```
groupadd mysql
useradd -s /sbin/nologin -g mysql -M mysql // 创建一个用户，不允许登录和不创建主目录
tail -1 /etc/passwd // 检查创建的用户
```
修改/usr/local/mysql权限
```
chown -R mysql:mysql /usr/local/mysql
```
#### 4. 初始化配置

进入安装路径
```
cd /usr/local/mysql
```
进入安装路径，执行 初始化配置脚本，表
```
scripts/mysql_install_db --initialize --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql
```
> 注意5.7.17版本使用

```
./mysqld --initialize --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql
```

> 注意：初始化后会生成默认密码，请记录下来
==2016-10-14T17:36:51.794435Z 1 [Note] A temporary password is generated for root@localhost: W=XlQVLf/7Ra==

==后续必须修改默认密码，不然不能正常使用mysql。==

> 注：在启动mysql服务时，会按照一定次序搜索my.cnf，先在/etc目录下找，找不到则会搜索“$basedir/my.cnf”,在本例中就是/usr/local/mysql/my.cnf，这是新版本mysql的配置文件的默认位置

>注意：在CentOS 6.4版操作系统的最小安装完成后，在/etc目录下会存在一个my.cnf，需要将此文件更名为其他的名字，如：/etc/my.cnf.bak，否则，该文件会干扰源码安装的MySQL的正确配置，造成无法启动。
在使用"yum update"更新系统后，需要检查下/etc目录下是否会多出一个my.cnf，如果多出，将它重命名成别的。否则，MySQL将使用这个配置文件启动，可能造成无法正常启动等问题。

##### 调整配置文件和环境变量
将默认生成的my.cnf备份
```
mv /etc/my.cnf /etc/my.cnf.bak
cd /usr/local/mysql/support-files
```
拷贝配置文件模板为新的mysql配置文件
```
cp my-default.cnf /etc/my.cnf
```
可按需修改新的配置文件选项， 不修改配置选项， mysql则按默认配置参数运行.

如下是我修改配置文件/etc/my.cnf， 用于设置编码为utf8以防乱码
```
[mysqld]
character_set_server=utf8
init_connect='SET NAMES utf8'
[client]
default-character-set=utf8
```
创建mysql命令文件
```
ln -s /mysql/bin/mysql /usr/bin/
```
注：没有这个文件就没有mysql命令，不能在任意位置使用mysql 访问数据库


#### 5.启动mysql
添加服务，拷贝服务脚本到init.d目录，并设置开机启动
```
cp support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
chkconfig mysql on
service mysqld start
```

#### 6. 配置用户
mysql启动成功后，root默认没有密码，我们需要设置root密码
设置之前，我们需要先设置path，要不不能直接调用mysql\
修改/etc/profile文件，在文件末尾加入
```
PATH=/usr/local/mysql/bin:$PATH
export PATH
```
关闭文件，运行下面的命令，
```
source /etc/profile
```
现在，我们就可以直接在终端输入mysql了，执行
```
mysql -u root
mysql > SET PASSWORD = PASSWORD('123456');
mysql > exit
```

修改root密码
```
alter user 'root'@'localhost' identified by 'wenti@456.COM';
```

若要配置远程访问，执行
```
mysql > GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.%' IDENTIFIED BY 'password' WITH GRANT OPTION;
```
> password 为远程访问时的root密码，可以和本地的不同

#### 7. 配置防火墙
防火墙的3306端口默认没有开启，若要远程访问，需要开启这个端口\
打开/etc/sysconfig/iptables，添加如下内容：
```
-A INPUT -m state --state NEW -m tcp -p -dport 3306 -j ACCEPT
```

然后保存，关闭文件，在终端运行如下命令，刷新防火墙配置：
```
service iptables restart
```

配置成功

> CentOS 7中默认使用Firewalld做防火墙，所以修改iptables后，在重启系统后，根本不管用。

Firewalld中添加端口方法如下：
```
firewall-cmd --zone=public --add-port=3306/tcp --permanent 
firewall-cmd --reload
```


> 注意：
在低于Mysql 5.7.6的版本上，Mysql是使用mysql_install_db命令初始化数据库的，该命令会在安装Mysql的用户根目录下创建一个.mysql_secret文件，该文件记录了初始化生成的随机密码，用户可使用改密码登录Mysql并重新修改密码。
> 对于Mysql 5.7.6以后的5.7系列版本，Mysql使用mysqld --initialize或mysqld --initialize-insecure命令来初始化数据库，后者可以不生成随机密码。但是安装Mysql时默认使用的是前一个命令，这个命令也会生成一个随机密码。改密码保存在了Mysql的日志文件中。




#### 编译安装常见错误分析
原文链接[https://typecodes.com/web/solvemysqlcompileerror.html](https://typecodes.com/web/solvemysqlcompileerror.html)
##### * 没有安装mysql所需要的boost库

##### * MySQL server PID file could not be found![失败]
Starting MySQL...The server quit without updating PID file (/usr/local/mysql/data/rekfan.pid).[失败]

1.可能是/usr/local/mysql/data/rekfan.pid文件没有写的权限
解决方法 ：给予权限，执行 “chown -R mysql:mysql /var/data” “chmod -R 755 /usr/local/mysql/data”  然后重新启动mysqld！

2.可能进程里已经存在mysql进程
解决方法：用命令“ps -ef|grep mysqld”查看是否有mysqld进程，如果有使用“kill -9  进程号”杀死，然后重新启动mysqld！

3.可能是第二次在机器上安装mysql，有残余数据影响了服务的启动。
解决方法：去mysql的数据目录/data看看，如果存在mysql-bin.index，就赶快把它删除掉吧，它就是罪魁祸首了。本人就是使用第三条方法解决的 ！http://blog.rekfan.com/?p=186

4.mysql在启动时没有指定配置文件时会使用/etc/my.cnf配置文件，请打开这个文件查看在[mysqld]节下有没有指定数据目录(datadir)。
解决方法：请在[mysqld]下设置这一行：datadir = /usr/local/mysql/data

5.skip-federated字段问题
解决方法：检查一下/etc/my.cnf文件中有没有没被注释掉的skip-federated字段，如果有就立即注释掉吧。

6.错误日志目录不存在
解决方法：使用“chown” “chmod”命令赋予mysql所有者及权限

7.selinux惹的祸，如果是centos系统，默认会开启selinux
解决方法：关闭它，打开/etc/selinux/config，把SELINUX=enforcing改为SELINUX=disabled后存盘退出重启机器试试。


##### 在丢失root密码的时候，可以这样
```
　　mysqld_safe --skip-grant-tables&

　　mysql -u root mysql

　　mysql> UPDATE user SET authentication_string=PASSWORD("new password") WHERE user='root';

　　mysql> FLUSH PRIVILEGES;收起
```
修改完毕。重启
```
killall -TERM mysqld。
```



