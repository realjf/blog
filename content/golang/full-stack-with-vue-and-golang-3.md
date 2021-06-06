---
title: "golang和vue3全栈开发之三 clean架构 Full Stack  With Vue and Golang 3"
date: 2021-06-06T23:50:36+08:00
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
│   ├── main.go
│   └── model
│       ├── errors.go
│       ├── interfaces.go
│       └── user.go
├── docker-compose.yml
├── echo.code-workspace
├── .env.dev
└── .gitignore
```

### clean architecture
![clean架构](/image/clean-arch.png)
### entity数据层的model
执行go get -u github.com/google/uuid，
创建account/model/user.go文件，其内容如下：
```go
package model

import "github.com/google/uuid"

type User struct {
	UID      uuid.UUID `db:"uid" json:"uid"`
	Email    string    `db:"email" json:"email"`
	Password string    `db:"password" json:"-"`
	Name     string    `db:"name" json:"name"`
	ImageURL string    `db:"image_url" json:"imageUrl"`
	Website  string    `db:"website" json:"website"`
}

```
创建account/model/interfaces.go文件，其内容如下：
```go
package model

import "github.com/google/uuid"

type UserService interface {
	Get(uid uuid.UUID) (*User, error)
}

type UserRepository struct {
	FindByUID(uid uuid.UUID) (*User, error)
}
```
创建account/model/errors.go文件，其内容如下：
```go
package model

import (
	"errors"
	"fmt"
	"net/http"
)

type Type string

const (
	Authorization   Type = "AUTHORIZATION"   // Authorization failure
	BadRequest      Type = "BADREQUEST"      // validation errors / bad input
	Conflict        Type = "CONFLICT"        // already exists - 409
	Internal        Type = "INTERNAL"        // Server and fallback errors
	NotFound        Type = "NOTFOUND"        // for not finding resource
	PayloadTooLarge Type = "PAYLOADTOOLARGE" // for uploading tons of JSON, or an image over the limit - 413
)

type Error struct {
	Type    Type   `json:"type"`
	Message string `json:"message"`
}

func (e *Error) Error() string {
	return e.Message
}

func (e *Error) Status() int {
	switch e.Type {
	case Authorization:
		return http.StatusUnauthorized
	case BadRequest:
		return http.StatusBadRequest
	case Conflict:
		return http.StatusConflict
	case Internal:
		return http.StatusInternalServerError
	case NotFound:
		return http.StatusNotFound
	case PayloadTooLarge:
		return http.StatusRequestEntityTooLarge
	default:
		return http.StatusInternalServerError
	}
}

func Status(err error) int {
	var e *Error
	if errors.As(err, &e) {
		return e.Status()
	}
	return http.StatusInternalServerError
}

func NewAuthorization(reason string) *Error {
	return &Error{
		Type:    Authorization,
		Message: reason,
	}
}

func NewBadRequest(reason string) *Error {
	return &Error{
		Type:    BadRequest,
		Message: fmt.Sprintf("Bad request. Reason: %v", reason),
	}
}

func NewConflict(name string, value string) *Error {
	return &Error{
		Type:    Conflict,
		Message: fmt.Sprintf("resource: %v with value: %v already exists", name, value),
	}
}

func NewInternal() *Error {
	return &Error{
		Type:    Internal,
		Message: fmt.Sprintf("Internal server error."),
	}
}

func NewNotFound(name string, value string) *Error {
	return &Error{
		Type:    NotFound,
		Message: fmt.Sprintf("resource: %v with value: %v not found", name, value),
	}
}

func NewPayloadTooLarge(maxBodySize int64, contentLength int64) *Error {
	return &Error{
		Type:    PayloadTooLarge,
		Message: fmt.Sprintf("Max payload size of %v exceeded. Actual payload size: %v", maxBodySize, contentLength),
	}
}

```
