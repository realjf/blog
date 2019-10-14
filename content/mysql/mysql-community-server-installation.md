---
title: "Mysql Community Server Installation(mysql 8.0.17 社区版本安装教程)"
date: 2019-10-14T17:50:16+08:00
draft: false
---

## 一、下载安装
下载地址：[https://downloads.mysql.com/archives/community/](https://downloads.mysql.com/archives/community/)

```bash
# 下载
wget https://downloads.mysql.com/archives/get/file/mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz
xz -d mysql-8.0.17-linux-glibc2.12-x86_64.tar.xz
tar xvf mysql-8.0.17-linux-glibc2.12-x86_64.tar

# 移动到你需要安装的目录下
mv mysql-8.0.17-linux-glibc2.12-x86_64 /usr/local/mysql

```
## 二、配置
#### 1. 在mysql根目录下创建一个新的data目录，用于存放数据
```bash
cd /usr/local/mysql
mkdir data
```

#### 2. 创建mysql用户组和mysql用户
```bash
groupadd mysql
useradd -g mysql mysql

```

#### 3. 改变mysql目录权限
```bash
chown -R mysql.mysql /usr/local/mysql/
```

#### 4. 初始化数据库
````bash
# 创建mysql_install_db安装文件
mkdir mysql_install_db
chmod 777 ./mysql_install_db

# 初始化数据库
bin/mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data

# 记录好自己的临时密码

````
#### 5. mysql配置
```bash
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
```
修改my.cnf文件

```bash
vim /etc/my.cnf
[mysqld]
    basedir = /usr/local/mysql   
    datadir = /usr/local/mysql/data
    socket = /usr/local/mysql/mysql.sock
    character-set-server=utf8
    port = 3306
   sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
 [client]
   socket = /usr/local/mysql/mysql.sock
   default-character-set=utf8
```
保存退出

#### 6. 建立mysql服务
```bash
cp -a ./support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
# 如果mysql.server里的basedir和datadir与配置不一样，需要修改

# 添加开机自启动

```

#### 7. 配置全局环境变量
编辑 /etc/profile文件
```bash
# 添加如下内容
export PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/lib

# 立即生效
source /etc/profile

```

#### 8. 启动mysql服务
```bash
service mysqld start

# 查看初始化密码
cat /root/.mysql_secret

```

#### 9. 登录mysql
```bash
mysql -uroot -p密码

# 修改密码
SET PASSWORD FOR 'root'@localhost=PASSWORD('123456');

```

#### 10. 设置远程登录
```bash
mysql> use mysql
mysql> update user set host='%' where user='root' limit 1;
mysql> flush privileges;

```
然后开放3306端口
```bash
firewall-cmd --permanent --add-port=3306/tcp
# 重启防火墙
firewall-cmd --reload

```




