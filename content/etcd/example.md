---
title: "etcd使用实例 ETCD Example"
date: 2021-04-12T15:50:55+08:00
keywords: ["etcd"]
categories: ["etcd"]
tags: ["etcd"]
series: [""]
draft: false
toc: false
related:
  threshold: 50
  includeNewer: true
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

### 下载安装
下载地址[https://github.com/etcd-io/etcd/releases](https://github.com/etcd-io/etcd/releases)

```sh
wget https://github.com/etcd-io/etcd/releases/download/v3.4.15/etcd-v3.4.15-linux-amd64.tar.gz

tar zxvf etcd-v3.4.15-linux-amd64.tar.gz
cd etcd-v3.4.15-linux-amd64
```
### 启动服务
```sh
# 目录中的etcd为服务端程序，etcdctl为客户端程序
# 启动服务
./etcd --listen-client-urls 'http://127.0.0.1:2379' --advertise-client-urls 'http://0.0.0.0:2379'

# --listen-client-urls 用于客户端通信的url，可以监听多个
# --advertise-client-urls 建议使用的客户端通信url
```


### 客户端常见命令
```sh
# 1. 获取一个键值对
./etcdctl get name

# 2. 设置一个键值对
./etcdctl put name value

# 3. 删除键值对
./etcdctl del name

# etcd的key是有序存储的，本质上是字符串，可以模拟出目录的结构，例如：/a/b，/a/b/c，/a/b/d 三个key，由于他们在存储
# 中的顺序排列，通过定位到key=/a/b并依次顺序向后扫描，就会遇到/a/b/c和/a/b/d这两个子目录.

# 4. 也可以获取某个目录下的所有key，需要加上--prefix参数
./etcdctl get "/a/b" --prefix

# 5. 删除所有key
./etcdctl del "/a/b" --prefix

```
### watch命令
可以使用watch命令监测key的变化，该命令会建立长连接。
由于etcd采用mvcc多版本并发控制，etcd的watch可以从给定的revision进行检测。
```sh
# 开始监听某个key
./etcdctl watch "/a/b"

# 在另外一个窗口执行
./etcdctl put "/a/b" "print"

# 原监听窗口输出如下：
./etcdctl watch "/a/b"
PUT
/a/b
print

# 同样，可以使用--prefix命令指定观察的key的前缀。
```

### 租约
租约是一段时间，可以通过lease grant命令授予租约，获得租约id后，可以为某个key附加上租约
```sh
# 创建一个30s的租约，注意：租约其实时间从创建租约开始，而不是使用租约的时候开始
./etcdctl lease grant 30
lease 694d78c50e58ef09 granted with TTL(30s)

# 使用租约id为某个key附加租约
./etcdctl put --lease=694d78c50e58ef09 "/a/b/e" "!"

# 30秒后get下可以发现已经删除了

# 可以进行自动续租，需在租约有效期内进行续约
./etcdctl lease grant 30
lease 694d78c50e58ef16 granted with TTL(30s)

# 到期自动续租
./etcdctl keep-alive 694d78c50e58ef16
lease 694d78c50e58ef1a keepalived with TTL(30)
lease 694d78c50e58ef1a keepalived with TTL(30)
lease 694d78c50e58ef1a keepalived with TTL(30)

```

### golang操作etcd

#### 执行get/put/delete
```golang

```



