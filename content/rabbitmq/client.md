---
title: "rabbitmq go客户端库实现"
date: 2020-04-28T14:49:47+08:00
keywords: ["rabbitmq"]
categories: ["rabbitmq"]
tags: ["rabbitmq"]
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



> go rabbitmq client library
```golang
go get github.com/streadway/amqp
```

#### send.go（消息发送者）
```golang
package main

import (
	"log"
	"fmt"
	"github.com/streadway/amqp"
)

func failOnError(err error, msg string){
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
		panic(fmt.Sprintf("%s: %s", msg, err))
	}
}

func main(){
	conn, err := amqp.Dial("amqp://guest:guest@localhost:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	q, err := ch.QueueDeclare(
		"hello",
		false,
		false,
		false,
		false,
		nil,
	)
	failOnError(err, "Failed to declare a queue")

	body := "hello"
	// 发布消息
	err = ch.Publish(
		"",
		q.Name,
		false,
		false,
		amqp.Publishing{
			ContentType: "text/plain",
			Body: []byte(body),
		})
	failOnError(err, "Failed to publish a message")


}

```

#### receive.go（消息接收者）
```golang
package main

import (
	"github.com/streadway/amqp"
	"log"
	"fmt"
)

func failOnError(err error, msg string){
	if err != nil {
		log.Fatalf("%s: %s", msg, err)
		panic(fmt.Sprintf("%s: %s", msg, err))
	}
}

func main(){
	conn, err := amqp.Dial("amqp://guest:guest@localhost:5672/")
	failOnError(err, "Failed to connect to RabbitMQ")
	defer conn.Close()

	ch, err := conn.Channel()
	failOnError(err, "Failed to open a channel")
	defer ch.Close()

	q, err := ch.QueueDeclare(
		"hello",
		false,
		false,
		false,
		false,
		nil,
	)
	failOnError(err, "Failed to declare a queue")

	msgs, err := ch.Consume(
		q.Name,
		"",
		true,
		false,
		false,
		false,
		nil,
	)
	failOnError(err, "Failed to register a consumer")

	forever := make(chan bool)

	go func() {
		for d := range msgs {
			log.Printf("Received a message: %s", d.Body)
		}
	}()

	log.Printf(" [*] Waiting for messages. To exit press CTRL+C")
	<-forever
}


```


之后运行
```
go run send.go
go run receive.go
```

即可看到返回结果如下：
```
2018/03/13 23:27:32  [*] Waiting for messages. To exit press CTRL+C
2018/03/13 23:27:32 Received a message: hello

```