---
title: "zookeeper集群搭建 Zookeeper cluster Set Up"
date: 2020-05-11T11:06:43+08:00
keywords: ["zookeeper", "distributed"]
categories: ["distributed"]
tags: ["zookeeper", "distributed"]
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


### 准备环境
- 准备4个centos7虚拟机
- 下载zookeeper安装包
- 提前安装好jdk [安装jdk](/linux/jdk-8u131/)

zookeeper下载地址：[http://mirrors.hust.edu.cn/apache/zookeeper/](http://mirrors.hust.edu.cn/apache/zookeeper/)

### 集群规划
- node1： leader或follower
- node2： leader或follower
- node3： leader或follower
- node4： observer

> leader：能接收所有的读写请求，也可以处理所有的读写请求，而且整个集群中的所有写数据请求都是由leader进行处理
> follower：能接收所有的读写请求，但是读数据请求自己处理，写数据请求转发给leader
> observer：跟follower的唯一的区别就是没有选举权和被选举权


### 下载安装
```bash
wget http://mirrors.hust.edu.cn/apache/zookeeper/stable/apache-zookeeper-3.5.7-bin.tar.gz

tar zxvf apache-zookeeper-3.5.7-bin.tar.gz

# 加入环境变量path中
vim ~/.bash_profile

export ZOOKEEPER_HOME=/home/hadoop/apps/zookeeper
export PATH=$PATH:$ZOOKEEPER_HOME/bin

# 保存退出，然后source使其生效
source ~/.bash_profile

```

### 配置zoo.cfg文件
```bash
# 进入ZOOKEEPER_HOME/conf目录
# 复制zoo_sample.cfg为zoo.cfg
cp zoo_sample.cfg zoo.cfg
# 编辑zoo.cfg
vi zoo.cfg

# 集群各节点的心跳时间间隔，保持默认即可(2s)
tickTime=2000

# 此配置表示，允许follower连接并同步到leader的初始化连接时间
# 它以tickTime的倍数来表示
# 当超过设置倍数的tickTime时间，则连接失败
# 保持默认即可(10次心跳的时间，即20s)
initLimit=10

# follower与leader通信，从发送请求到接收到响应的等待时间的最大值，保持默认即可，即10s
# 如果10s内没有收到响应，本次请求就失败
syncLimit=5

# zookeeper的数据存放的位置，默认是/tmp/zookeeper，一定要改，因为tmp目录会不定时清空
dataDir=/root/hadoop/zkdata

# 客户端连接的端口号，保持默认即可
clientPort=2181

# 以下内容手动添加
# server.id=主机名:心跳端口:选举端口
# 注意：这里给每个节点定义了id，这些id写到配置文件中
# id为1-255之间的任意的不重复的数字，一定要记得每个节点的id的对应关系
server.1=node1:2888:3888
server.2=node2:2888:3888
server.3=node3:2888:3888
server.4=node4:2888:3888:observer
```
### hosts配置
为每个虚拟机配置hosts，以便后续根据主机名操作
如node1配置如下
```bash
192.168.37.200 node1
192.168.37.201 node2
192.168.37.202 node3
192.168.37.203 node4

```
其他节点依次配置

### 同步配置
其他虚拟机按同样配置设置好，或者直接复制到相应机器
```bash
scp -r /home/hadoop/apps/zookeeper node2:/home/hadoop/apps/
scp -r /home/hadoop/apps/zookeeper node3:/home/hadoop/apps/
scp -r /home/hadoop/apps/zookeeper node4:/home/hadoop/apps/

```

### 在配置的dataDir目录下新建myid文件，并写入id
```bash
mkdir -p /home/hadoop/zkdata
cd /home/hadoop/zkdata

echo 1 > myid # 这里的id根据上面的配置server.1这个确定相应节点的id

```

### 启动集群
每个节点都需要操作
```bash
zkServer.sh start
```

查看每个节点状态
```bash
zkServer.sh status
```

至此，zookeeper集群安装配置成功







