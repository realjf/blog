---
title: "免秘钥登录配置 Ssh Login Nopassword"
date: 2020-05-11T16:20:44+08:00
keywords: ["linux"]
categories: ["linux"]
tags: ["linux"]
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
### 方法一
在一个节点生成公钥，然后利用ssh-copy-id复制到各节点

```bash
ssh-keygen -t rsa -b 4096 -P '' -f ~/.ssh/id_rsa -C "备注"

# 复制到各节点
ssh-copy-id node2
ssh-copy-id node3
ssh-copy-id node4

# 其他节点重复上述操作，实现各节点之间可以相互免密登录
```

### 方法二
也可以使用shell脚本，需要提前安装好expect

```bash
yum install expect -y
```

autoSSH.sh
```bash
#!/bin/bash

## 脚本接收的参数，也就是要互相配置 SSH 免密登录的服务器列表参数
BASE_HOST_LIST=$*

## 密码，默认用户是当前运行脚本的用户，比如 root 用户
## 这里改成你的用户对应的密码
BASE_PASSWORD="root"

## shell 函数：模拟 SSH 公钥私钥文件生成的人机交互过程
sshkeygen(){
    expect -c "
    spawn ssh-keygen
    expect {
        \"ssh/id_rsa):\" {send \"\r\";exp_continue}
        \"passphrase):\" {send \"\r\";exp_continue}
        \"again:\" {send \"\r\";exp_continue}
    }
    "
}

## shell 函数：模拟配置 SSH 免密登录过程的人机交互过程
sshcopyid(){
    expect -c "
    spawn ssh-copy-id $1
    expect {
        \"(yes/no)?\" {send \"yes\r\";exp_continue}
        \"password:\" {send \"$2\r\";exp_continue}
    }
    "
}

## 本机生成密钥对
sshkeygen 

## 然后本机跟其他服务器建立 SSH 免密登录(包括自己)
for SSH_HOST in ${BASE_HOST_LIST}
do
    sshcopyid ${SSH_HOST} ${BASE_PASSWORD}
done
```
上述脚本实现某个节点对其他任意节点免秘钥登录

如果需要各节点都能免秘钥登录，要需要以下的脚本，将上述脚本发送到各节点运行

startAutoSSH.sh
```bash
#!/bin/bash

## 配置 SSH 免密登录的服务器列表，可写死，也可通过传参或者读配置文件的方式读取
#BASE_HOST_LIST="node1 node2 node3 node4"
BASE_HOST_LIST=$*

## 脚本的放置目录（传送之前，和传送之后都是这个目录）
SCRIPT_PATH="/root/autoSSH.sh"

## 第一步：先让自己先跑 autoSSH.sh 脚本，为了能顺利发送脚本到集群各节点
sh ${SCRIPT_PATH} ${BASE_HOST_LIST}

## 第二步：把脚本发送给其他服务器，让其他服务器也执行该脚本
for SSH_HOST in $BASE_HOST_LIST
do
    ## first : send install script
    ## 注意这行，用户名写死为root，如果是其他用户，记得在这里修改
    scp -r $SCRIPT_PATH root@${SSH_HOST}:$SCRIPT_PATH
    ## send command and generate ssh and auto ssh
    ssh ${SSH_HOST} sh ${SCRIPT_PATH} ${BASE_HOST_LIST}
done
```

运行演示
```bash
sh startAutoSSH.sh node1 node2 node3 node4
```