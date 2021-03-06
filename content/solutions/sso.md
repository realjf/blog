---
title: "解决方案 之 用jwt实现CAS单点登录方案 SSO"
date: 2021-04-12T13:32:01+08:00
keywords: ["solutions", "sso", "cas"]
categories: ["solutions"]
tags: ["solutions", "sso", "cas"]
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

### 什么是单点登录(SSO)？
单点登录译作：Single Sign On（简称SSO）。其旨在用户通过一次登录即可在多个应用系统之间，访问所有互相信任的应用系统的服务，
而提供这种访问方式的技术就是SSO技术。

要实现SSO，需要以下主要功能：

- 所有应用系统共享一个身份认证系统。统一的认证系统是SSO的前提之一，认证系统的主要功能是对用户登录信息进行校验，校验通过后生成统一的认证标志返回给用户。当然认证系统还需要对认证标志进行校验。
- 所有应用系统能够识别和提取认证标志信息，即所有应用系统必须能识别用户是否已登录过，且通过与认证系统通信，判断登录信息是否有效，而从完成单点登录功能。


SSO的实现大致可以分成Cookie和Session机制两大类。

- Session是一种服务器端机制，当客户端访问服务器时，服务器为客户端创建一个惟一的SessionID，以使在整个交互过程中始终保持状态，而交互的信息则可由应用自行指定，因此用Session方式实现SSO，不能在多个浏览器之间实现单点登录，但却可以跨域。
- Cookie是一种客户端机制，它存储的内容主要包括：名称、值、过期时间、路径和域，路径与域合在一起就构成了Cookie的作用范围，因此用Cookie方式可实现SSO，但域名必须相同。

### 什么是CAS？
CAS是Central Authentiction Service 的缩写,中央认证服务。
CAS是耶鲁大学发起的企业级的、开源的项目，旨在为Web应用系统提供一种可靠的单点登录解决方案。

#### CAS原理
CAS包含CAS Server和CAS Client两个部分。

- CAS Server 负责完成对用户的认证工作，需要独立部署，CAS Server 会处理用户名/ 密码等凭证(Credentials)，并生成统一的认证票据Ticket。
- CAS Client 负责处理对客户端受保护资源的访问请求，需要对请求方进行身份认证时，重定向到CAS Server进行认证。原则上，客户端应用不再接受任何的用户名密码等。CAS Client与受保护的客户端应用部署在一起，通过确认登录认证有效的方式保护受保护的资源。

#### CAS协议
##### 基础协议
CAS 基础协议按照如下步骤进行：
- 访问资源：用户发起请求访问应用系统（即CAS客户端）受保护的资源
- 重定向认证：CAS客户端通过分析请求中得出没有认证票据，说明用户没有进行身份认证，于是，重定向请求到CAS服务器进行身份认证，并把用户访问CAS客户端的URL作为参数传递给CAS服务器
- 用户认证：CAS服务器接收到身份认证请求后转向登录页面，用户提供认证信息后进行身份认证。身份认证成功后，CAS服务器以SSL方式给浏览器返回一个TGC(用户身份信息凭证，用于以后在CAS服务器获取身份认证信息)
- 发放票据：CAS服务器会生成一个随机的票据，然后让浏览器重定向到CAS客户端
- 验证票据：CAS客户端接收到用户提交的票据后，向CAS服务器验证票据是否有效，验证通过后，允许用户访问受保护资源
- 传输用户信息系：CAS服务器验证票据通过后，传输用户认证结果信息给CAS客户端


##### 代理协议
CAS基础协议已经基本上满足大部分简单的SSO应用，现在讨论更复杂一点的情况：用户访问服务A，服务A又依赖于服务B来获取一些信息，如：
```sh
User --> ServiceA --> ServiceB
```
这种情况，假设服务B也是需要对用户进行身份验证才能访问的，那么，为了不影响用户体验，CAS引入了一种Proxy认证机制，即CAS Client可以代理用户去访问其他web应用系统。

代理的前提是CAS客户端要拥有用户的身份信息（类似前面的TGC），而PGT(由CAS Server颁发给拥有票据的服务，PGT绑定一个用户的特定服务，使其拥有向CAS Server申请，获得PT的能力)，凭借TGC，用户可以获取访问其他web服务的票据，所以，凭借PGT，CAS客户端可以从CAS服务器获取访问代理应用的PT（是应用程序代理用户身份对目标程序进行访问的凭证），于是web应用系统可以代理用户去实现后端的认证，而无需前端用户的参与。

#### CAS的安全性
CAS的安全性依赖于SSL，并且其安全性要求远高于普通的应用系统。

##### TGC/PGT 安全性
对于一个CAS用户来说，最重要的是保护它的TGC，如果TGC不慎被CAS服务端以外的实体获取，其可以通过该TGC，然后冒充用户访问所有授权资源。

PGT跟TGC的角色一样，如果被其他实体截取，其后果如上。

TGC是CAS服务器通过SSL方式发送给终端用户，因此，要截取TGC的难度非常大。另外，TGC也有自己的存活周期，设置其在合适的范围内，可以在不影响SSO体验的前提下增加安全性，默认是120分钟。

##### 票据和PT 安全性
票据是通过http传送的，所以票据可以被截取到，CAS协议从以下几个方面增加安全性：

- 票据只能使用一次，CAS协议规定，无论票据验证是否成功，CAS服务端都会将服务端的缓存中清除该票据，从而确认票据仅被使用一次
- 票据在一段时间内失效，默认5分钟
- 票据是随机产生的

### 使用jwt实现CAS方案流程图介绍
下面的时序图，分别模拟了用户访问系统A和系统B时的五种场景

![sso-cas-1](/image/sso-cas-1.png)

在场景一里：

- 在验证的jwt的时候，通过jwt的payload里面存储的之前创建的SSO的会话id, 可以通过会话id验证用户会话是否有效，有效则返回存储在会话里的用户信息等
- CAS服务里面的session id需要考虑唯一性以及session共享的问题（假如CAS采用集群部署的话）。session共享可以通过redis或者memcached等进行管理，设置其有效期正好可以实现到期自动销毁。

![sso-cas-2](/image/sso-cas-2.png)

![sso-cas-3](/image/sso-cas-3.png)

![sso-cas-4](/image/sso-cas-4.png)

![sso-cas-5](/image/sso-cas-5.png)

为了让方案安全性更高，如下方式一定要设置：

- 使用https
- cookie设置http only
- 注意防范CSRF攻击，可以在jwt里面加入一个系统标识，添加一个验证，只有传过来的jwt内的系统标识与发起jwt验证请求的服务一致的情况下，才允许验证通过




**参考文献**
- [http://www.360doc.com/content/15/0204/17/21706453_446251626.shtml](http://www.360doc.com/content/15/0204/17/21706453_446251626.shtml)
- [https://www.cnblogs.com/lyzg/p/6132801.html](https://www.cnblogs.com/lyzg/p/6132801.html)