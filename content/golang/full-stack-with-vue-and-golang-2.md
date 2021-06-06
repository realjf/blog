---
title: "golang和vue3全栈开发之二 创建路由处理程序 Full Stack  With Vue and Golang 2"
date: 2021-06-06T23:21:02+08:00
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


### 项目结构
```sh
.
├── account
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum
│   ├── handler
│   │   └── handler.go
│   └── main.go
├── docker-compose.yml
├── echo.code-workspace
├── .env.dev
└── .gitignore
```
### 创建路由处理程序
创建account/handler/handler.go文件，其内容如下：
```go
package handler

import (
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

type Handler struct{}

type Config struct {
	R *gin.Engine
}

func NewHandler(c *Config) {
	h := &Handler{}

	g := c.R.Group(os.Getenv("ACCOUNT_API_URL"))

	g.GET("/me", h.Me)
	g.POST("/signup", h.Signup)
	g.POST("/signin", h.Signin)
	g.POST("/signout", h.Signout)
	g.POST("/tokens", h.Tokens)
	g.POST("/image", h.Image)
	g.DELETE("/image", h.DeleteImage)
	g.PUT("/details", h.Details)
}

func (h *Handler) Me(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's me",
	})
}

func (h *Handler) Signup(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's signup",
	})
}

func (h *Handler) Signin(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's signin",
	})
}

func (h *Handler) Signout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's signout",
	})
}

func (h *Handler) Tokens(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's tokens",
	})
}

func (h *Handler) Image(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's image",
	})
}

func (h *Handler) DeleteImage(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's deleteImage",
	})
}

func (h *Handler) Details(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"message": "it's details",
	})
}

```
然后，修改account/main.go文件，增加路由处理程序
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
	"github.com/realjf/echo/handler"
)

func main() {
	log.Println("Starting server...")

	router := gin.Default()

	// 路由处理程序
	handler.NewHandler(&handler.Config{
		R: router,
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
在项目根目录下新增.env.dev文件，其内容如下：
```env
ACCOUNT_API_URL=/api/account
```
在项目根目录下新增.gitignore文件，其内容如下：
```gitignore
.env.dev
```

修改docker-compose.yml文件
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
        # .env file
        env_file: .env.dev
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
然后重新运行docker-compose up，
```sh
...

Starting echo_reverse-proxy_1 ... done
Recreating echo_account_1     ... done
Attaching to echo_reverse-proxy_1, echo_account_1
account_1        | [00] Starting service
reverse-proxy_1  | time="2021-06-06T15:42:12Z" level=info msg="Configuration loaded from flags."
account_1        | [00] 2021/06/06 15:42:12 Starting server...
account_1        | [00] [GIN-debug] [WARNING] Creating an Engine instance with the Logger and Recovery middleware already attached.
account_1        | [00]
account_1        | [00] [GIN-debug] [WARNING] Running in "debug" mode. Switch to "release" mode in production.
account_1        | [00]  - using env:   export GIN_MODE=release
account_1        | [00]  - using code:  gin.SetMode(gin.ReleaseMode)
account_1        | [00]
account_1        | [00] [GIN-debug] GET    /api/account/me           --> github.com/realjf/echo/handler.(*Handler).Me-fm (3 handlers)
account_1        | [00] [GIN-debug] POST   /api/account/signup       --> github.com/realjf/echo/handler.(*Handler).Signup-fm (3 handlers)
account_1        | [00] [GIN-debug] POST   /api/account/signin       --> github.com/realjf/echo/handler.(*Handler).Signin-fm (3 handlers)
account_1        | [00] [GIN-debug] POST   /api/account/signout      --> github.com/realjf/echo/handler.(*Handler).Signout-fm (3 handlers)
account_1        | [00] [GIN-debug] POST   /api/account/tokens       --> github.com/realjf/echo/handler.(*Handler).Tokens-fm (3 handlers)
account_1        | [00] [GIN-debug] POST   /api/account/image        --> github.com/realjf/echo/handler.(*Handler).Image-fm (3 handlers)
account_1        | [00] [GIN-debug] DELETE /api/account/image        --> github.com/realjf/echo/handler.(*Handler).DeleteImage-fm (3 handlers)
account_1        | [00] [GIN-debug] PUT    /api/account/details      --> github.com/realjf/echo/handler.(*Handler).Details-fm (3 handlers)
account_1        | [00] 2021/06/06 15:42:12 Listening on port :8080
```
现在，可以通过curl工具访问了
```sh
curl -X POST http://malcorp.test/api/account/signup
```

