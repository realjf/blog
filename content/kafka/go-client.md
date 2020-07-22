---
title: "Kafka Go Client"
date: 2020-04-29T15:37:44+08:00
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

本次实验假定您已经安装好了kafka（单机或者集群），且配置好了远程访问地址，详见配置文件config/server.properties

### 首先需要下载安装librdkafka
```bash
wget https://github.com/edenhill/librdkafka/archive/v1.4.0.tar.gz
tar zxvf librdkafka-1.4.0.tar.gz
cd librdkafka-1.4.0
./configure
make
make install

```
安装完毕，可以开始写go client

### 在go项目下安装客户端
```bash
go get -u gopkg.in/confluentinc/confluent-kafka-go.v1/kafka
```

### consumer示例
```go

import (
	"fmt"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

func main() {

	c, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": "192.168.37.133:9092",
		"group.id":          "1",
		"auto.offset.reset": "earliest",
	})

	if err != nil {
		panic(err)
	}

	c.SubscribeTopics([]string{"test", "^aRegex.*[Tt]est"}, nil)

	for {
		msg, err := c.ReadMessage(-1)
		if err == nil {
			fmt.Printf("Message on %s: %s\n", msg.TopicPartition, string(msg.Value))
		} else {

			fmt.Printf("Consumer error: %v (%v)\n", err, msg)
		}
	}

	c.Close()
}
```
### producer示例
```go
import (
	"fmt"
	"gopkg.in/confluentinc/confluent-kafka-go.v1/kafka"
)

func main() {
	p, err := kafka.NewProducer(&kafka.ConfigMap{"bootstrap.servers": "192.168.37.133:9092"})
	if err != nil{
		panic(err)
	}
	defer p.Close()

	go func() {
		for e := range p.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					fmt.Printf("Delivery failed: %v\n", ev.TopicPartition)
				}else{
					fmt.Printf("Delivered message to %v\n", ev.TopicPartition)
				}
			}
		}
	}()

	topic := "test"
	for _, word := range []string{"Welcome", "to", "the", "Confluent", "kafka", "Golang", "client"} {
		p.Produce(&kafka.Message{
			TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
			Value: []byte(word),
		}, nil)
	}

	// 等待消息发送
	p.Flush(15 * 1000)
}

```


