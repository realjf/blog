---
title: "storm安装"
date: 2020-04-28T15:31:08+08:00
keywords: ["storm"]
categories: ["storm"]
tags: ["storm"]
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

### 一、需要安装的工具
        python、zookeeper、storm（如果是storm0.9以前的版本，则需要安装zeromq、jzmq）
### 二、开始安装
#### 第一步：安装Python2.7.2
```shell
wget http://www.python.org/ftp/python/2.7.2/Python-2.7.2.tgz
tar zxvf Python-2.7.2.tgz
cd Python-2.7.2
./configure --prefix=/usr/local/python2.7
make
make install
vi /etc/ld.so.conf

追加/usr/local/lib/
sudo ldconfig

```
#### 第二步：安装zookeeper   
```shell
wget http://mirrors.cnnic.cn/apache/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz
tar -zxvf zookeeper-3.3.5.tar.gz 
cp  -R zookeeper-3.3.5  /usr/local/zookeeper
vim /etc/profile (设置ZOOKEEPER_HOME和ZOOKEEPER_HOME/bin) 
export ZOOKEEPER_HOME="/usr/local/zookeeper"
export PATH=$PATH:$ZOOKEEPER_HOME/bin
cp /usr/local/zookeeper/conf/zoo_sample.cfg /usr/local/zookeeper/conf/zoo.cfg (用zoo_sample.cfg制作$ZOOKEEPER_HOME/conf/zoo.cfg)
mkdir /tmp/zookeeper
mkdir /var/log/zookeeper
```
zookeeper的单机安装已经完成了。

#### 第三步：安装zeromq
```shell
wget http://download.zeromq.org/zeromq-4.1.0-rc1.tar.gz
tar zxf zeromq-2.2.0.tar.gz 
cd zeromq-2.2.0
./configure     //因为jzmq的安装时依赖于zeromq的，所以./configure的时候不能指定zeromq的安装目录，如果指定了，则jzmq的安装会出错（即不能指定--prefix=...）。
make
make install
sudo ldconfig (更新LD_LIBRARY_PATH)
```
zeromq安装完成。
注意：如有有依赖报错，需要安装：
jzmq dependencies 依赖包
sudo yum install uuid*
sudo yum install libtool
sudo yum install libuuid 
sudo yum install libuuid-devel

#### 第四步：安装jzmq
jzmq的安装是依赖zeromq的，所以应该先装zeromq，再装jzmq
```shell
git clone git://github.com/nathanmarz/jzmq.git(需先安装git，才能git clone文件)
cd jzmq
./autogen.sh
./configure
make
make install
```

报错修复：
- 1、在./autogen.sh这步如果报错：autogen.sh:error:could not find libtool is required to run autogen.sh，这是因为缺少了libtool。解决方法：yum install libtool
- 2、make[1]: *** 没有规则可以创建“org/zeromq/ZMQ.class”需要的目标“classdist_noinst.stamp”。 停止
   修正方法，创建classdist_noinst.stamp文件。解决方法：touch src/classdist_noinst.stamp 
- 3、无法访问 org.zeromq.ZMQ 。解决方法：进入src目录，手动编译相关java代码：javac -d . org/zeromq/*.java
          4、在./configure的时候报,not include “zmf.c.。解决方案：看自己的zeromq是否安装在默认目录了，如果没有，重新安装
#### 第五步，安装Storm
```shell
wget http://mirrors.cnnic.cn/apache/storm/apache-storm-0.9.4/apache-storm-0.9.4.tar.gz
unzip  apache-storm-0.9.4.zip
mv storm-0.8.1 /usr/local/storm
ln -s /usr/local/storm-0.8.1/ /usr/local/storm
vim /etc/profile
export STORM_HOME=/usr/local/storm-0.8.1
export PATH=$PATH:$STORM_HOME/bin

```
到此为止单机版的Storm就安装完毕了。
### 三、测试运行
#### 一、运行storm的官方demo
- a：在eclipse里面创建一个java项目
- b：将storm安装路径的lib中的jar包导入夏目
- c：将storm安装路径中的/examples/storm-starter/src/jvm 里面的storm文件夹直接拷贝到java项目的src路径下
- d：看是否有报错，如果有报错，解决一下报错（如果jdk版本是1.8的，则会报一些错误，主要是@override）
- f：运行包storm.starter中的topology例子
#### 二、配置及启动zookeeper
配置内容：
```
# The number of milliseconds of each tick  
tickTime=2000  
# The number of ticks that the initial   
# synchronization phase can take  
initLimit=10  
# The number of ticks that can pass between   
# sending a request and getting an acknowledgement  
syncLimit=5  
# the directory where the snapshot is stored.  
# do not use /tmp for storage, /tmp here is just   
# example sakes.  
dataDir=/home/username/zookeeper-3.4.5/tmp/zookeeper-data  
dataLogDir=/home/username/zookeeper-3.4.5/tmp/logs  
# the port at which the clients will connect  
clientPort=2181 
``` 
单机版直接启动：  /usr/local/zookeeper/bin/zkServer.sh start
#### 三、配置storm
文件在/usr/local/storm/conf/storm.yaml
配置内容如下：
```shell
storm.zookeeper.servers:
  - 127.0.0.1
 storm.zookeeper.port: 2181
 nimbus.host: "127.0.0.1"
 ui.port: 9098
 storm.local.dir: "/tmp/storm"
```
> 注意：在配置时一定注意在每一项的开始时要加空格，冒号后也必须要加空格，否则storm就不认识这个配置文件了。

说明：
- storm.local.dir表示storm需要用到的本地目录。
- nimbus.host表示那一台机器是master机器，即 nimbus。
- storm.zookeeper.servers表示哪几台机器是zookeeper服务器。
- storm.zookeeper.port表 示zookeeper的端口号，这里一定要与zookeeper配置的端口号一致，否则会出现通信错误，切记切记。
- superevisor.slot.port和supervisor.slots.ports表示supervisor节点的槽数，就是最多能跑几个 worker进程（每个sprout或bolt默认只启动一个worker，但是可以通过conf修改成多个）。
#### 四、执行
```shell
# bin/storm nimbus（启动主节点）
# bin/storm supervisor（启动从节点）
执行命令：# storm jar StormStarter.jar storm.starter.WordCountTopology test  //此命令的作用就是用storm将jar发送给storm去执行，后面的test是定义的toplogy名称。
# bin/storm ui （启动ui，可以通过 ip:8080/ 查看运行i情况）
# bin/storm logviewer 启动Log Viewer进程
```

