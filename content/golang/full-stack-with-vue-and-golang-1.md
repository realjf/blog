---
title: "golang和vue3全栈开发之一 自动重载go环境构建 Full Stack With Vue 3 and Golang 1"
date: 2021-06-06T23:04:00+08:00
keywords: ["golang", "vuejs"]
categories: ["golang", "vuejs"]
tags: ["golang", "vuejs"]
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

### 准备
- ubuntu 20.04
- go v1.16 
- docker and docker-compose

### 项目目录
```
.
├── account
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum
│   └── main.go
├── docker-compose.yml
└── echo.code-workspace
```
### echo.code-workspace内容
```sh
cat echo.code-workspace
{
    "folders": [
        {
            "path": "account"
        },
        {
            "path": "."
        }
    ]
}      
```
运行
```sh
# 打开编辑项目
code echo.code-workspace
```

### 初始化项目
在项目account目录下运行
```sh
go mod init github.com/realjf/echo
```
执行go get -u github.com/gin-gonic/gin，
然后创建account/main.go文件，其内容如下：
```go
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	log.Println("Starting server...")

	router := gin.Default()

	router.GET("/api/account", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"message": "hello world",
		})
	})

	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	go func() {
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to init server: %v\n", err)
		}
	}()

	log.Printf("Listening on port %v\n", srv.Addr)

	quit := make(chan os.Signal)

	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	<-quit

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	log.Println("Shutting down server...")
	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v\n", err)
	}
}

```
之后创建account/Dockerfile文件，其内容如下：
```dockerfile
FROM golang:alpine as builder 

WORKDIR /go/src/app 

ENV GO111MODULE=on

ENV GOPROXY=https://goproxy.cn,direct
RUN go get github.com/cespare/reflex

COPY go.mod .
COPY go.sum .

RUN go mod download  

COPY . .
RUN go build -o ./run .

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /go/src/app/run .


EXPOSE 8080
CMD ["./run"]

```
其中，github.com/cespare/reflex，其作用是当文件改变时运行命令行，
之后在项目根目录下创建docker-compose.yml文件，其内容如下：
```yml
version: "3.8"

services:
    reverse-proxy:
        image: traefik:v2.2
        command:
            - "--api.insecure=true"
            - "--providers.docker"
            - "--providers.docker.exposedByDefault=false"
        ports:
            - "80:80"
            - "8080:8080"
        volumes:
            - /var/run/docker.sock:/var/run/docker.sock
    account:
        build:
            context: ./account
            target: builder
        image: account
        expose:
            - "8080"
        labels:
            - "traefik.enable=true"
            - "traefik.http.routers.account.rule=Host(`malcorp.test`) && PathPrefix(`/api/account`)"
        environment:
            - ENV=dev
        volumes:
            - ./account:/go/src/app
        command: reflex -r "\.go$$" -s -- sh -c "go run ./"

```
其中malcorp.test是自定义的域名，用于访问api服务，可以在hosts文件中加入如下内容
```sh
127.0.0.1 malcorp.test
```
之后运行docker-compose up，启动docker
```sh
...

Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them
WARNING: Image for service account was built because it did not already exist. To rebuild this image you must use `docker-compose build` or `docker-compose up --build`.
Creating echo_account_1       ... done
Creating echo_reverse-proxy_1 ... done
Attaching to echo_account_1, echo_reverse-proxy_1
account_1        | [00] Starting service
reverse-proxy_1  | time="2021-06-06T14:54:44Z" level=info msg="Configuration loaded from flags."
account_1        | [00] 2021/06/06 14:54:45 Starting server...
account_1        | [00] [GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.
account_1        | [00]
account_1        | [00] [GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
account_1        | [00]  - using env:   export GIN_MODE=release
account_1        | [00]  - using code:  gin.SetMode(gin.ReleaseMode)
account_1        | [00]
account_1        | [00] [GIN-debug] GET    /api/account              --> main.main.func1 (3 handlers)
account_1        | [00] 2021/06/06 14:54:45 Listening on port :8080
```
运行成功后，浏览器访问地址：malcorp.test/api/account即可

