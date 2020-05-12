---
title: "hadoop高可用集群搭建 Hadoop cluster high available Set Up"
date: 2020-05-11T10:42:55+08:00
keywords: ["bigdata", "hadoop"]
categories: ["bigdata"]
tags: ["bigdata", "hadoop"]
series: [""]
draft: true
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
- 准备4个基于centos7 的虚拟机，主机名为node1、node2、node3、node4 (sudo hostnamectl set-hostname xxxx)
- 为每个虚拟机创建一个拥有sudoers权限的hadoop用户，直接修改/etc/sudoers文件夹，新增一行 username ALL=(ALL) ALL 即可
- 为每个虚拟机安装jdk
- 为每个虚拟机设置[免密登录](/linux/ssh-login-nopassword/)
- 为每个虚拟机设置时间同步
- 集群已安装zookeeper集群 [zookeeper-set-up](/distributed/zookeeper-set-up/)


hadoop下载地址：[https://mirrors.aliyun.com/apache/hadoop/common/](https://mirrors.aliyun.com/apache/hadoop/common/)

### 集群规划
![hadoop-cluster](/image/hadoop-cluster.png)

### 安装
#### 下载解压安装
```bash
wget https://mirrors.aliyun.com/apache/hadoop/common/stable/hadoop-3.2.1.tar.gz

tar zxvf hadoop-3.2.1.tar.gz -C /home/hadoop/apps/
```
#### 修改hadoop-env.sh、mapred-env.sh、yarn-env.sh这三个配置文件，添加JAVA_HOME
在hadoop的配置文件在HADOOP_HOME/etc/hadoop/下
```bash
export JAVA_HOME=/usr/local/jdk1.8.0_161
```








