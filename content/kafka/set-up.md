---
title: "Kafka快速开始"
date: 2020-04-28T17:13:30+08:00
keywords: ["kafka"]
categories: ["kafka"]
tags: ["kafka"]
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

下载地址：[https://www.apache.org/dyn/closer.cgi?path=/kafka/2.5.0/kafka_2.12-2.5.0.tgz](https://www.apache.org/dyn/closer.cgi?path=/kafka/2.5.0/kafka_2.12-2.5.0.tgz)

### 下载
```bash
wget https://www.apache.org/dyn/closer.cgi?path=/kafka/2.5.0/kafka_2.12-2.5.0.tgz
tar zxvf kafka_2.12-2.5.0.tgz
cd kafka_2.12-2.5.0

```
### 开启服务器
```bash
# 开启zookeeper
bin/zookeeper-server-start.sh config/zookeeper.properties

# 开启kafka
bin/kafka-server-start.sh config/server.properties

```

### 创建一个topic
```bash
bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic test
```
上面创建了一个叫test的topic

我们现在可以运行list topic命令查看刚才创建的topic
```bash
bin/kafka-topics.sh --list --bootstrap-server localhost:9092
```

### 发送消息
```bash
bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic test
这是一条信息
这是另外一条消息

```

### 开启一个消费者consumer
接收消息
```bash
bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
这是一条信息
这是另一条信息

```

### 安装一个多broker集群，即kafka集群
```bash
# 首先为每个broker创建一个配置
cp config/server.properties config/server-1.properties
cp config/server.properties config/server-2.properties

# 然后为每个配置文件设置
config/server-1.properties:
    broker.id=1
    listeners=PLAINTEXT://:9093
    log.dirs=/tmp/kafka-logs-1
   
config/server-2.properties:
    broker.id=2
    listeners=PLAINTEXT://:9094
    log.dirs=/tmp/kafka-logs-2

```
broker.id是broker的唯一标识

现在启动另外两个节点
```bash
bin/kafka-server-start.sh config/server-1.properties &

...

bin/kafka-server-start.sh config/server-2.properties &

```
现在创建一个新的topic用三个副本
```bash
bin/kafka-topics.sh --create --bootstrap-server localhost:9092 --replication-factor 3 --partitions 1 --topic my-replicated-topic
```

可以查看topic的描述
```bash
bin/kafka-topics.sh --describe --bootstrap-server localhost:9092 --topic my-replicated-topic

```




