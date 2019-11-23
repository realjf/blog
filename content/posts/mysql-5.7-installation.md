---
title: "Mysql 5.7.27源码安装教程"
date: 2019-10-15T09:11:41+08:00
keywords: ["mysql", "mysql安装", "mysql5.7", "mysql源码安装"]
categories: ["database"]
tags: ["mysql", "mysql安装", "mysql server", "mysql5.7", "mysql源码安装"]
draft: false
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


## 准备
- debian 9操作系统
- mysql下载地址：[https://downloads.mysql.com/archives/get/file/mysql-5.7.27.tar.gz](https://downloads.mysql.com/archives/get/file/mysql-5.7.27.tar.gz)
- boost下载地址：[http://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz](http://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz)


## 下载安装
### 1. 下载安装boost
```bash

wget http://nchc.dl.sourceforge.net/project/boost/boost/1.59.0/boost_1_59_0.tar.gz

tar zxvf boost_1_59_0.tar.gz
mv boost_1_59_0 /usr/local/boost

```
### 2. 下载安装mysql
```bash
# 安装依赖包
apt-get install libncurses-dev


# 创建mysql用户组和用户
groupadd mysql
useradd mysql -s /sbin/nologin -M -g mysql

# 下载mysql
wget https://downloads.mysql.com/archives/get/file/mysql-5.7.27.tar.gz

tar zxvf mysql-5.7.27.tar.gz
cd mysql-5.7.27

# 创建必要的文件夹
mkdir /usr/local/mysql
mkdir /usr/local/mysql/data # 数据库文件
mkdir /usr/local/mysql/tmp # sock文件
mkdir /usr/local/mysql/logs # 错误日志文件
mkdir /usr/local/mysql/binlog # binlog日志文件

# 编译mysql
cmake . -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
 -DMYSQL_DATADIR=/usr/local/mysql/data \
 -DMYSQL_UNIX_ADDR=/usr/local/mysql/tmp/mysql.sock \
 -DDEFAULT_CHARSET=utf8 \
 -DDEFAULT_COLLATION=utf8_general_ci \
 -DEXTRA_CHARSETS=gbk,gb2312,utf8,ascii \
 -DENABLED_LOCAL_INFILE=ON \
 -DWITH_INNOBASE_STORAGE_ENGINE=1 \
 -DWITH_FEDERATED_STORAGE_ENGINE=1 \
 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
 -DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
 -DWITHOUT_PARTITION_STORAGE_ENGINE=1 \
 -DWITH_ZLIB=bundled \
 -DWITH_EMBEDDED_SERVER=1 \
 -DWITH_DEBUG=0 \
 -DWITH_BOOST=/usr/local/boost
 

# 如果看到如下信息表示编译完成
-- Configuring done
-- Generating done
-- Build files have been written to: /path/to/mysql

# 执行make安装
make && make install

# 安装完成

```


### 3. 配置mysql系统环境变量
```bash
vim /etc/profile

PATH=$PATH:/usr/local/mysql/bin

# 使其生效
source /etc/profile

```
### 4. 配置my.cnf文件

```bash
# 更改mysql安装目录的属主和属组
chown -R mysql:mysql /usr/local/mysql

# 修改my.cnf文件的组和用户
chown mysql:mysql /etc/my.cnf

# 修改my.cnf配置
vim /etc/my.cnf

[client]
port = 3306
socket = /usr/local/mysql/tmp/mysql.sock
default-character-set = utf8

[mysqld]
port = 3306
user = mysql
basedir = /usr/local/mysql
datadir = /usr/local/mysql/data
pid-file = /usr/local/mysql/mysqld.pid
socket = /usr/local/mysql/tmp/mysql.sock
tmpdir = /usr/local/mysql/tmp
character_set_server = utf8
server-id = 1
max_connections = 100
max_connect_errors = 10
sql_mode = NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER,NO_AUTO_VALUE_ON_ZERO,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,PIPES_AS_CONCAT,ANSI_QUOTES
log-bin = /usr/local/mysql/binlog/mysql-bin
log-error = /usr/local/mysql/logs/mysql_5_7_27.err

```
### 5. 初始化数据库
```bash
cd /usr/local/mysql
./bin/mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

```

### 6. 开启ssl连接
```bash
cd /usr/local/mysql
./bin/mysql_ssl_rsa_setup --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

Generating a 2048 bit RSA private key
............+++
.............................................+++
writing new private key to 'ca-key.pem'
-----
Generating a 2048 bit RSA private key   
......+++
...................................+++
writing new private key to 'server-key.pem'
-----
Generating a 2048 bit RSA private key
.....................................................................................................+++
........................+++
writing new private key to 'client-key.pem'
-----

```

### 7. 启动mysql数据库
```bash
# 拷贝启动脚本到/etc/init.d/目录下，并改名mysqld
cp support-files/mysql.server /etc/init.d/mysqld

# 重新加载系统服务，将mysql数据库加入开机启动
/bin/systemctl daemon-reload
/bin/systemctl enable mysqld.service

# 启动mysql数据库，并检查端口监听状态
/etc/init.d/mysqld start

```

### 8. mysql数据库基本优化（安全）
```bash
# 删除全部用户，添加额外管理员，重新加载mysql授权表

mysql> select user,host from mysql.user;

# 授权新账号
mysql> grant all privileges on *.* to username@'localhost' identified by 'password' with grant option;

# 删除新账号
mysql> delete from mysql.user where user='mysql.session';
mysql> delete from mysql.user where user='mysql.sys';

# 删除root账号
mysql> delete from mysql.user where user='root';

# 刷新权限
mysql>flush privileges;

```
### 9. 优雅关闭mysql数据库的方法
```bash
# 使用mysql自带脚本
/etc/init.d/mysqld stop
# 使用mysqladmin
mysqladmin -uusername -ppassword shutdown

```

### 10. 授权远程用户连接mysql数据库的方法
```bash
mysql> grant all privileges on *.* to username@'ip address' identified by 'password' with grant option;

mysql> flush privileges;

```
