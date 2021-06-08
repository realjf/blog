---
title: "Docker Compose Specification"
date: 2021-06-07T09:06:14+08:00
keywords: ["docker"]
categories: ["docker"]
tags: ["docker"]
series: [""]
draft: true
toc: true
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

[toc]
### 示例
以下示例通过一个具体的示例应用程序说明了 Compose 规范概念。该示例是非规范的。 考虑将应用程序拆分为前端 Web 应用程序和后端服务。 前端在运行时使用由基础设施管理的 HTTP 配置文件进行配置，提供外部域名，以及由平台的安全密钥库注入的 HTTPS 服务器证书。 后端将数据存储在持久卷中。 这两个服务在隔离的后层网络上相互通信，而前端也连接到前层网络并公开端口 443 供外部使用。
```sh
(External user) --> 443 [frontend network]
                            |
                  +--------------------+
                  |  frontend service  |...ro...<HTTP configuration>
                  |      "webapp"      |...ro...<server certificate> #secured
                  +--------------------+
                            |
                        [backend network]
                            |
                  +--------------------+
                  |  backend service   |  r+w   ___________________
                  |     "database"     |=======( persistent volume )
                  +--------------------+        \_________________/

```
示例应用程序由以下部分组成： 
  - 2 个服务，由 Docker 镜像支持：webapp 和 database 
  - 1个secret（HTTPS证书），注入前端 
  - 1个配置（HTTP），注入前端 
  - 1 个持久卷，附加到后端 
  - 2个网络
```yml
services:
  frontend:
    image: awesome/webapp
    ports:
      - "443:8043"
    networks:
      - front-tier
      - back-tier
    configs:
      - httpd-config
    secrets:
      - server-certificate

  backend:
    image: awesome/database
    volumes:
      - db-data:/etc/data
    networks:
      - back-tier

volumes:
  db-data:
    driver: flocker
    driver_opts:
      size: "10GiB"

configs:
  httpd-config:
    external: true

secrets:
  server-certificate:
    external: true

networks:
  # The presence of these objects is sufficient to define them
  front-tier: {}
  back-tier: {}

```
此示例说明了卷、配置和机密之间的区别。虽然它们都作为挂载的文件或目录暴露给服务容器，但只有一个卷可以配置为读写访问。 Secrets 和 configs 是只读的。卷配置允许您选择卷驱动程序并传递驱动程序选项以根据实际基础设施调整卷管理。 Configs 和 Secrets 依赖于平台服务，并被声明为外部，因为它们不作为应用程序生命周期的一部分进行管理：Compose 实现将使用特定于平台的查找机制来检索运行时值。

### Compose file
Compose 文件是一个 YAML 文件，定义了版本 (DEPRECATED)、服务 (REQUIRED)、网络、卷、配置和机密。 Compose 文件的默认路径是工作目录中的 compose.yaml（首选）或 compose.yml。 Compose 实现还应该支持 docker-compose.yaml 和 docker-compose.yml 以实现向后兼容性。如果两个文件都存在，则 Compose 实现必须更喜欢规范的 compose.yaml 之一。 

多个 Compose 文件可以组合在一起来定义应用程序模型。 YAML 文件的组合必须通过基于用户设置的 Compose 文件顺序附加/覆盖 YAML 元素来实现。简单的属性和映射被最高阶的 Compose 文件覆盖，列表通过追加来合并。相对路径必须根据第一个 Compose 文件的父文件夹进行解析，每当合并的免费文件托管在其他文件夹中时。 

由于某些 Compose 文件元素既可以表示为单个字符串也可以表示为复杂对象，因此合并必须适用于展开的表单。

#### 简介 
配置文件允许针对各种用途和环境调整 Compose 应用程序模型。 Compose 实现应该允许用户定义一组活动配置文件。确切的机制是特定于实现的，可能包括命令行标志、环境变量等。 

服务顶级元素支持配置文件属性来定义命名配置文件列表。没有配置文件属性集的服务必须始终启用。当列出的配置文件中没有一个与活动的配置文件匹配时，Compose 实现必须忽略服务，除非该服务被命令明确定位。在那种情况下，必须将其配置文件添加到活动配置文件集中。所有其他顶级元素不受配置文件的影响并且始终处于活动状态。 

对其他服务的引用（通过links、extends或共享资源语法 service:xxx）不得自动启用否则将被活动配置文件忽略的组件。相反，Compose 实现必须返回一个错误。
```yml
services:
  foo:
    image: foo
  bar:
    image: bar
    profiles:
      - test
  baz:
    image: baz
    depends_on:
      - bar
    profiles:
      - test
  zot:
    image: zot
    depends_on:
      - bar
    profiles:
      - debug

```
- 在未启用配置文件的情况下解析的 Compose 应用程序模型仅包含 foo 服务。 
- 如果启用了配置文件测试，则模型包含由测试配置文件启用的服务 bar 和 baz，以及始终启用的服务 foo。 
- 如果启用配置文件调试，模型包含 foo 和 zot 服务，但不包含 bar 和 baz，因此模型对于 zot 的 depends_on 约束无效。 
- 如果配置文件调试和测试启用，模型包含所有服务：foo、bar、baz 和 zot。 
- 如果 Compose 实现使用 bar 作为显式服务运行，即使用户未启用测试配置文件，它和测试配置文件也将处于活动状态。 
- 如果 Compose 实现是使用 baz 作为显式服务运行的，则服务 baz 和配置文件测试将处于活动状态，并且 bar 将被depends_on 约束拉入。 
- 如果 Compose 实现是使用 zot 作为显式服务来运行的，那么模型对于 zot 的 depends_on 约束将再次无效，因为 zot 和 bar 没有列出公共配置文件。 
- 如果 Compose 实现使用 zot 作为显式服务运行并启用配置文件测试，则配置文件调试将自动启用，并且服务栏作为启动服务 zot 和 bar 的依赖项被拉入。

### Version 顶级元素
顶级 version 属性由向后兼容性规范定义，但仅供参考。 

Compose 实现不应该使用这个版本来选择一个精确的模式来验证 Compose 文件，而是更喜欢它被设计时的最新模式。 

Compose 实现应该验证它们可以完全解析 Compose 文件。如果某些字段是未知的，通常是因为 Compose 文件是用较新版本的规范定义的字段编写的，Compose 实现应该警告用户。 Compose 实现可以提供忽略未知字段的选项（由“loose”模式定义）。
### Services 顶级元素

服务是应用程序中计算资源的抽象定义，可以独立于其他组件进行扩展/替换。服务由一组容器支持，由平台根据复制要求和放置约束运行。在容器的支持下，服务由一个 Docker 镜像和一组运行时参数定义。服务中的所有容器都是使用这些参数创建的。 

Compose 文件必须将服务根元素声明为映射，其键是服务名称的字符串表示，其值是服务定义。服务定义包含应用于为该服务启动的每个容器的配置。 

每个服务还可以包括一个 Build 部分，它定义了如何为服务创建 Docker 镜像。 Compose 实现可能支持使用此服务定义构建 docker 镜像。如果没有实现，构建部分应该被忽略并且撰写文件必须仍然被认为是有效的。 

构建支持是 Compose 规范的一个可选方面，这里有详细描述 

每个服务都定义了运行其容器的运行时约束和要求。部署部分对这些约束进行分组，并允许平台调整部署策略，以最好地将容器的需求与可用资源相匹配。 

部署支持是 Compose 规范的一个可选方面，在此处进行了详细描述。如果没有实现 Deploy 部分应该被忽略并且 Compose 文件仍然必须被认为是有效的。

#### deploy
deploy 指定服务的部署和生命周期的配置，如此处所定义。

#### blkio_config
blkio_config 定义了一组配置选项来为此服务设置块 IO 限制。
```yml
services:
  foo:
    image: busybox
    blkio_config:
       weight: 300
       weight_device:
         - path: /dev/sda
           weight: 400
       device_read_bps:
         - path: /dev/sdb
           rate: '12mb'
       device_read_iops:
         - path: /dev/sdb
           rate: 120
       device_write_bps:
         - path: /dev/sdb
           rate: '1024k'
       device_write_iops:
         - path: /dev/sdb
           rate: 30

```
**device_read_bps, device_write_bps**
为给定设备上的读/写操作设置每秒字节数限制。列表中的每个项目必须有两个键：

  - path：定义受影响设备的符号路径。 
  - rate：作为表示字节数的整数值或作为表示字节值的字符串。

**device_read_iops, device_write_iops**
为给定设备上的读/写操作设置每秒操作数限制。列表中的每个项目必须有两个键：

  - path：定义受影响设备的符号路径。 
  - rate：作为表示每秒允许的操作数的整数值。

**weight**
修改分配给该服务相对于其他服务的带宽比例。采用 10 到 1000 之间的整数值，默认值为 500。

**weight_device**
按设备微调带宽分配。列表中的每一项都必须有两个键：

  - path：定义受影响设备的符号路径。 
  - weight：10 到 1000 之间的整数值。

#### cpu_count
cpu_count 定义了服务容器可用的 CPU 数量。

#### cpu_percent
cpu_percent 定义了可用 CPU 的可用百分比。

#### cpu_shares 
cpu_shares 定义（作为整数值）服务容器相对于其他容器的 CPU 权重。 

#### cpu_period
当平台基于 Linux 内核时，cpu_period 允许 Compose 实现配置 CPU CFS（完全公平调度程序）周期。 

#### cpu_quota 
当平台基于 Linux 内核时，cpu_quota 允许 Compose 实现配置 CPU CFS（完全公平调度程序）配额。 

#### cpu_rt_runtime 
cpu_rt_runtime 为支持实时调度程序的平台配置 CPU 分配参数。可以是以微秒为单位或持续时间的整数值。
```yml
cpu_rt_runtime: '400ms'
cpu_rt_runtime: 95000`
```
#### cpu_rt_period 
cpu_rt_period 为支持实时调度程序的平台配置 CPU 分配参数。可以是以微秒为单位或持续时间的整数值。
```yml
cpu_rt_period: '1400us'
cpu_rt_period: 11000`
```
#### cpus
已弃用：使用 deploy.reservations.cpus 
cpus 定义分配给服务容器的（可能是虚拟的）CPU 的数量。这是一个小数。 0.000 表示没有限制。

#### cpuset 
cpuset 定义了允许执行的显式 CPU。可以是范围 0-3 或列表 0,1

#### build
build 指定用于从源创建容器映像的构建配置，如定义here。

#### cap_add
cap_add 将附加容器功能指定为字符串
```yml
cap_add:
  - ALL
```
#### cap_drop 
cap_drop 指定要作为字符串删除的容器功能。
```yml
cap_drop:
  - NET_ADMIN
  - SYS_ADMIN
```
#### cgroup_parent
cgroup_parent 为容器指定一个可选的父 cgroup。
```yml
cgroup_parent: m-executor-abcd
```

#### command
command 覆盖容器镜像（即 Dockerfile 的 CMD）声明的默认命令。
```yml
command: bundle exec thin -p 3000
```
该命令也可以是一个列表，类似于 Dockerfile：
```yml
command: [ "bundle", "exec", "thin", "-p", "3000" ]
```

#### configs
configs 使用 per-service configs 配置在每个服务的基础上授予对配置的访问权限。支持两种不同的语法变体。 

如果 config 在平台上不存在或未在此 Compose 文件的 configs 部分中定义，则 Compose 实现必须报告错误。 

为配置定义了两种语法。为了保持符合本规范，实现必须支持这两种语法。实现必须允许在同一文档中使用短句和长句。

**short语法**
简短的语法变体仅指定配置名称。这会授予容器访问配置的权限，并将其安装在容器内的 /<config_name> 处。源名称和目标安装点都设置为配置名称。 

以下示例使用简短语法授予 redis 服务访问 my_config 和 my_other_config 配置的权限。 my_config 的值设置为./my_config.txt 文件的内容，my_other_config 定义为外部资源，表示已经在平台中定义。如果外部配置不存在，部署必须失败。
```yml
services:
  redis:
    image: redis:latest
    configs:
      - my_config
configs:
  my_config:
    file: ./my_config.txt
  my_other_config:
    external: true

```
**长语法**
长语法为如何在服务的任务容器中创建配置提供了更多的粒度。 

  - source：平台中存在的配置名称。 
  - target：要挂载在服务的任务容器中的文件的路径和名称。如果未指定，则默认为 /<source>。 
  - uid 和 gid：在服务的任务容器中拥有已挂载配置文件的数字 UID 或 GID。未指定时的默认值是 USER 运行容器。 
  - mode：安装在服务的任务容器中的文件的权限，以八进制表示法。默认值是世界可读的 (0444)。可写位必须被忽略。可执行位可以设置。 
  
以下示例在容器内将 my_config 的名称设置为 redis_config，将模式设置为 0440（组可读）并将用户和组设置为 103。redis 服务无权访问 my_other_config 配置。
```yml
services:
  redis:
    image: redis:latest
    configs:
      - source: my_config
        target: /redis_config
        uid: "103"
        gid: "103"
        mode: 0440
configs:
  my_config:
    external: true
  my_other_config:
    external: true
```
您可以授予一个服务访问多个配置的权限，并且可以混合使用长短语法。

#### container_name
container_name 是一个字符串，用于指定自定义容器名称，而不是生成的默认名称。
```yml
container_name: my-web-container
```
如果 Compose 文件指定了 container_name，则 Compose 实现不得将服务扩展到一个容器之外。尝试这样做必须导致错误。 如果存在，container_name 应该遵循 [a-zA-Z0-9][a-zA-Z0-9_.-]+ 的正则表达式格式

#### credential_spec
credential_spec 配置托管服务帐户的凭据规范。 

使用 Windows 容器支持服务的Compose实现必须支持文件：和注册表：credential_spec 的协议。 Compose 实现还可以支持自定义用例的附加协议。 

credential_spec 必须采用 file://<filename> 或 registry://<value-name> 格式。
```yml
credential_spec:
  file: my-credential-spec.json
```
使用 registry: 时，从守护进程主机上的 Windows 注册表中读取凭证规范。具有给定名称的注册表值必须位于：
```sh
HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Virtualization\Containers\CredentialSpecs
```
以下示例从注册表中名为 my-credential-spec 的值加载凭据规范：
```yml
credential_spec:
  registry: my-credential-spec
```
**gMSA 配置示例**
在为服务配置 gMSA 凭证规范时，您只需要使用 config 指定凭证规范，如下例所示：
```yml
services:
  myservice:
    image: myimage:latest
    credential_spec:
      config: my_credential_spec

configs:
  my_credentials_spec:
    file: ./my-credential-spec.json|
```
#### depends_on
depends_on 表示服务之间的启动和关闭依赖关系。

**短语法**
简短的语法变体仅指定依赖项的服务名称。服务依赖会导致以下行为： 
  - compose实现必须按依赖顺序创建服务。在下面的例子中，db 和 redis 是在 web 之前创建的。 
  - compose实现必须按依赖顺序删除服务。在以下示例中，在 db 和 redis 之前删除了 web。 

简单的例子：
```yml
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```
Compose 实现必须保证在启动依赖服务之前已经启动了依赖服务。在启动依赖服务之前Compose实现可能会等待依赖服务“准备好”。

**长语法**
长格式语法允许配置不能用短格式表达的附加字段。 
  - condition：依赖被认为满足的条件 
    - service_started：相当于上面描述的简短语法 
    - service_healthy：指定依赖项在启动依赖服务之前应该是“健康的”（如健康检查所示）。 
    - service_completed_successfully：指定依赖项在启动依赖项服务之前应该运行到成功完成。 
  
  服务依赖会导致以下行为： 
    - Compose实现必须按依赖顺序创建服务。在下面的例子中，db 和 redis 是在 web 之前创建的。 
    - Compose实现必须等待健康检查传递标记为 service_healthy 的依赖项。在以下示例中，在创建 web 之前，db 应该是“健康的”。 
    - Compose实现必须按依赖顺序删除服务。在以下示例中，在 db 和 redis 之前删除了 web。 
    
简单的例子：
```yml
services:
  web:
    build: .
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
  redis:
    image: redis
  db:
    image: postgres

```
Compose 实现必须保证在启动依赖服务之前已经启动了依赖服务。在启动依赖服务之前，组合实现必须保证用 service_healthy 标记的依赖服务是“健康的”。

#### device_cgroup_rules
device_cgroup_rules 定义此容器的设备 cgroup 规则列表。该格式与 Linux 内核在控制组设备白名单控制器中指定的格式相同。
```yml
device_cgroup_rules:
  - 'c 1:3 mr'
  - 'a 7:* rmw'
```
#### devices
devices 为创建的容器定义了一个设备映射列表。
```yml
devices:
  - "/dev/ttyUSB0:/dev/ttyUSB0"
```
#### dns
dns 定义要在容器网络接口配置上设置的自定义 DNS 服务器。可以是单个值或列表。
```yml
dns: 8.8.8.8
```
```yml
dns:
  - 8.8.8.8
  - 9.9.9.9
```
#### dns_opt
dns_opt 列出要传递给容器的 DNS 解析器（Linux 上的 /etc/resolv.conf 文件）的自定义 DNS 选项。
```yml
dns_opt:
  - use-vc
  - no-tld-query
```
#### dns_search
dns 定义自定义 DNS 搜索域以在容器网络接口配置上设置。可以是单个值或列表。
```yml
dns_search: example.com
```
```yml
dns_search:
  - dc1.example.com
  - dc2.example.com
```
#### domainname
domainname 声明用于服务容器的自定义域名。必须是有效的 RFC 1123 主机名。

#### entrypoint
entrypoint 覆盖了 Docker 镜像的默认入口点（即由 Dockerfile 设置的 ENTRYPOINT）。当入口点由 Compose 文件配置时，Compose 实现必须清除 Docker 映像上的任何默认命令 - Dockerfile 中的 ENTRYPOINT 和 CMD 指令。如果还设置了命令，则将其用作入口点的参数，以替代 Docker 映像的 CMD
```yml
entrypoint: /code/entrypoint.sh
```
入口点也可以是一个列表，类似于 Dockerfile：
```yml
entrypoint:
  - php
  - -d
  - zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20100525/xdebug.so
  - -d
  - memory_limit=-1
  - vendor/bin/phpunit
```
#### env_file
env_file 根据文件内容向容器添加环境变量。
```yml
env_file: .env
```
env_file 也可以是一个列表。列表中的文件必须自上而下进行处理。对于在两个 env 文件中指定的相同变量，列表中最后一个文件的值必须保持不变。
```yml
env_file:
  - ./a.env
  - ./b.env
```
必须从 Compose 文件的父文件夹解析相对路径。由于绝对路径会阻止 Compose 文件的可移植性，因此 Compose 实现应该在使用此类路径设置 env_file 时警告用户。 

在 environment 部分声明的环境变量必须覆盖这些值——即使这些值是空的或未定义的，这也适用。

**Env_file格式**
env 文件中的每一行都必须是 VAR[=[VAL]] 格式。必须忽略以 # 开头的行。空行也必须被忽略。 

VAL 的值用作原始字符串，根本没有修改。如果该值被引号包围（shell 变量通常是这种情况），则必须将引号包含在传递给 Compose 实现创建的容器的值中。 

VAL 可以省略，在这种情况下变量值为空字符串。 =VAL 可以省略，在这种情况下变量未设置。
```env
# Set Rails/Rack environment
RACK_ENV=development
VAR="quoted"
```
#### environment
environment 定义在容器中设置的环境变量。环境可以使用数组或地图。任何布尔值； true、false、yes、no，必须用引号括起来，以确保它们不会被 YAML 解析器转换为 True 或 False。 

环境变量可以由单个键声明（没有等号的值）。在这种情况下，Compose 实现应该依赖于一些用户交互来解析值。如果没有，则变量未设置并将从服务容器环境中删除。 

Map语法：
```yml
environment:
  RACK_ENV: development
  SHOW: "true"
  USER_INPUT:
```
Array语法
```yml
environment:
  - RACK_ENV=development
  - SHOW=true
  - USER_INPUT
```
当为服务设置了 env_file 和 environment 时，由 environment 设置的值具有优先权。

#### expose
expose 定义了 Compose 实现必须从容器公开的端口。这些端口必须可供链接服务访问，并且不应发布到主机。只能指定内部容器端口。
```yml
expose:
  - "3000"
  - "8000"
```
#### extends
在当前文件或其他文件中扩展另一个服务，可选择覆盖配置。您可以将扩展与其他配置键一起用于任何服务。 extends 值必须是一个用所需服务和可选文件键定义的映射。
```yml
extends:
  file: common.yml
  service: webapp
```
如果支持 Compose 实现，则必须按以下方式处理扩展： 
  - service 定义作为基础引用的服务的名称，例如 web 或数据库。 
  - file 是定义该服务的 Compose 配置文件的位置。 

**限制**
以下限制适用于所引用的服务： 
  - 依赖于其他服务的服务不能用作基础。因此，任何引入对另一个服务的依赖的键都与扩展不兼容。此类键的非详尽列表是：links、volumes_from、容器模式（在 ipc、pid、network_mode 和 net 中）、服务模式（在 ipc、pid 和 network_mode 中）、depends_on。 
  - 服务不能有扩展的循环引用 
Compose 实现必须在所有这些情况下返回错误。 
  
**查找引用服务**
文件值可以是： 
  - 不存在。这表明正在引用同一 Compose 文件中的另一个服务。 
  - 文件路径，可以是： 
    - 相对路径。此路径被视为相对于主 Compose 文件的位置。 
    - 绝对路径。 
    
  由服务表示的服务必须存在于标识的引用 Compose 文件中。如果出现以下情况，Compose 实现必须返回错误： 
    - 未找到由 service 表示的服务 
    - 未找到由文件表示的撰写文件 
    
**合并服务定义**
必须按以下方式合并两个服务定义（当前 Compose 文件中的主要服务定义和扩展指定的引用服务定义）： 
  - 映射：主服务定义映射中的键覆盖引用服务定义映射中的键。未覆盖的键按原样包含在内。 
  - 序列：项目组合在一起成为一个新的序列。元素的顺序被保留，引用的项目在前，主要项目在后。 
  - 标量：主服务定义中的键优先于被引用的键。 

**映射**
以下键应视为映射：build.args、build.labels、build.extra_hosts、deploy.labels、deploy.update_config、deploy.rollback_config、deploy.restart_policy、deploy.resources.limits、environment、healthcheck、labels、logging .options、sysctls、storage_opt、extra_hosts、ulimits。 

适用于 healthcheck 的一个例外是主映射不能指定 disable: true ，除非引用的映射也指定 disable: true。在这种情况下，组合实现必须返回错误。 

例如，下面的输入：
```yml
services:
  common:
    image: busybox
    environment:
      TZ: utc
      PORT: 80
  cli:
    extends:
      service: common
    environment:
      PORT: 8080
```
为 cli 服务生成以下配置。如果使用数组语法，则会产生相同的输出。
```yml
environment:
  PORT: 8080
  TZ: utc
image: busybox
```
blkio_config.device_read_bps、blkio_config.device_read_iops、blkio_config.device_write_bps、blkio_config.device_write_iops、devices 和volumes 下的项目也被视为映射，其中key 是容器内的目标路径。 

例如，下面的输入：
```yml
services:
  common:
    image: busybox
    volumes:
      - common-volume:/var/lib/backup/data:rw
  cli:
    extends:
      service: common
    volumes:
      - cli-volume:/var/lib/backup/data:ro
```
为 cli 服务生成以下配置。请注意，挂载的路径现在指向新的卷名并应用了 ro 标志。
```yml
image: busybox
volumes:
- cli-volume:/var/lib/backup/data:ro
```
如果引用的服务定义包含扩展映射，则将其下的项简单地复制到新的合并定义中。然后再次开始合并过程，直到没有剩余的扩展键为止。

例如，下面的输入：
```yml
services:
  base:
    image: busybox
    user: root
  common:
    image: busybox
    extends:
      service: base
  cli:
    extends:
      service: common
```
为 cli 服务生成以下配置。在这里，cli 服务从公共服务中获取用户密钥，而公共服务又从基础服务中获取此密钥。
```yml
image: busybox
user: root
```
**序列**
以下键应视为序列：cap_add、cap_drop、configs、deploy.placement.constraints、deploy.placement.preferences、deploy.reservations.generic_resources、device_cgroup_rules、expose、external_links、ports、secrets、security_opt。合并产生的任何重复项都将被删除，以便序列仅包含唯一元素。 

例如，下面的输入：
```yml
services:
  common:
    image: busybox
    security_opt:
      - label:role:ROLE
  cli:
    extends:
      service: common
    security_opt:
      - label:user:USER
```
为 cli 服务生成以下配置。
```yml
image: busybox
security_opt:
- label:role:ROLE
- label:user:USER
```
如果使用列表语法，以下键也应视为序列：dns、dns_search、env_file、tmpfs。与上面提到的序列字段不同，合并产生的重复项不会被删除。

**标量**
服务定义中任何其他允许的键都应视为标量。

#### external_links
external_links 将服务容器链接到在此 Compose 应用程序之外管理的服务。 external_links 定义要使用平台查找机制检索的现有服务的名称。可以指定 SERVICE:ALIAS 形式的别名。
```yml
external_links:
  - redis
  - database:mysql
  - database:postgresql
```
#### extra_hosts
extra_hosts 将主机名映射添加到容器网络接口配置（Linux 为 /etc/hosts）。值必须以 HOSTNAME:IP 的形式为其他主机设置主机名和 IP 地址。
```yml
extra_hosts:
  - "somehost:162.242.195.82"
  - "otherhost:50.31.209.229"
```
Compose 实现必须在容器的网络配置中创建与 IP 地址和主机名匹配的条目，这意味着对于 Linux /etc/hosts 将获得额外的行：
```text
162.242.195.82  somehost
50.31.209.229   otherhost
```
#### group_add
group_add 指定容器内的用户必须是其成员的其他组（按名称或编号）。 

这很有用的一个例子是当多个容器（作为不同的用户运行）需要在共享卷上读取或写入相同的文件时。该文件可由所有容器共享的组拥有，并在 group_add 中指定。
```yml
services:
  myservice:
    image: alpine
    group_add:
      - mail
```
在创建的容器中运行 id 必须显示用户属于邮件组，如果 group_add 没有声明，情况就不会如此。
#### healthcheck
healthcheck 声明一个检查，用于确定此服务的容器是否“健康”。这会覆盖由服务的 Docker 映像设置的 HEALTHCHECK Dockerfile 指令。
```yml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost"]
  interval: 1m30s
  timeout: 10s
  retries: 3
  start_period: 40s
```
interval、timeout 和 start_period 被指定为持续时间。 

test 定义了 Compose 实现将运行以检查容器健康状况的命令。它可以是字符串或列表。如果是列表，则第一项必须是 NONE、CMD 或 CMD-SHELL。如果是字符串，则相当于指定 CMD-SHELL 后跟该字符串。
```yml
# Hit the local web app
test: ["CMD", "curl", "-f", "http://localhost"]
```
使用 CMD-SHELL 将使用容器的默认 shell（Linux 为 /bin/sh）运行配置为字符串的命令。以下两种形式是等价的：
```yml
test: ["CMD-SHELL", "curl -f http://localhost || exit 1"]
```
```yml
test: curl -f https://localhost || exit 1
```
NONE 禁用健康检查，主要用于禁用图像设置的健康检查。或者，可以通过设置 disable: true 来禁用图像设置的健康检查：
```yml
healthcheck:
  disable: true
```
#### hostname
hostname 声明用于服务容器的自定义主机名。必须是有效的 RFC 1123 主机名。

#### image
image 指定启动容器的镜像。图像必须遵循开放容器规范可寻址图像格式，如 [<registry>/][<project>/]<image>[:<tag>|@<digest>]。
```yml
    image: redis
    image: redis:5
    image: redis@sha356:0ed5d5928d4737458944eb604cc8509e245c3e19d02ad83935398bc4b991aac7
    image: library/redis
    image: docker.io/library/redis
    image: my_private.registry:5000/redis
```
如果平台上不存在该image，则 Compose 实现必须尝试根据 pull_policy 拉取它。具有构建支持的组合实现可以为最终用户提供替代选项来控制从源构建图像的优先级，但是拉动图像必须是默认行为。 

只要声明了构建部分，就可以从 Compose 文件中省略image。当 Compose 文件中缺少image时，没有构建支持的 Compose 实现必须失败。

#### init
init 在容器内运行一个 init 进程 (PID 1)，用于转发信号和收割进程。将此选项设置为 true 可为服务启用此功能。
```yml
services:
  web:
    image: alpine:latest
    init: true
```
使用的 init 二进制文件是特定于平台的。
#### ipc
ipc 配置服务容器设置的 IPC 隔离模式。可用值是特定于平台的，但 Compose 规范定义了特定值，如果支持，必须按照描述实现： 
  - 可共享，它为容器提供了自己的私有 IPC 命名空间，并有可能与其他容器共享它。 
  - service:{name} 使容器加入另一个（可共享的）容器的 IPC 命名空间。
```yml
    ipc: "shareable"
    ipc: "service:[service name]"
```
#### isolation
隔离指定容器的隔离技术。支持的值是特定于平台的。

#### labels
标签向容器添加元数据。您可以使用数组或地图。

建议您使用反向 DNS 表示法，以防止您的标签与其他软件使用的标签发生冲突。
```yml
labels:
  com.example.description: "Accounting webapp"
  com.example.department: "Finance"
  com.example.label-with-empty-value: ""
```
```yml
labels:
  - "com.example.description=Accounting webapp"
  - "com.example.department=Finance"
  - "com.example.label-with-empty-value"
```
Compose实现必须创建具有规范标签的容器： 
  - com.docker.compose.project 在 Compose 实现创建的所有资源上设置为用户项目名称 
  - com.docker.compose.service 在服务容器上设置，服务名称在 Compose 文件中定义 
  
com.docker.compose 标签前缀是保留的。在 Compose 文件中指定带有此前缀的标签必须导致运行时错误。

#### links
links 定义到另一个服务中容器的网络链接。指定服务名称和链接别名 (SERVICE:ALIAS)，或仅指定服务名称。
```yml
web:
  links:
    - db
    - db:database
    - redis
```
链接服务的容器必须可在与别名相同的主机名处访问，如果未指定别名，则为服务名称。 

链接不需要启用服务进行通信 - 当没有设置特定的网络配置时，任何服务必须能够访问默认网络上该服务名称的任何其他服务。如果服务确实声明了它们所连接的网络，则链接不应覆盖网络配置，并且未连接到共享网络的服务不应能够通信。 Compose 实现可能不会警告用户此配置不匹配。 

链接也以与depends_on相同的方式表达服务之间的隐式依赖，因此它们决定了服务启动的顺序。

#### logging
logging 定义服务的日志记录配置。
```yml
logging:
  driver: syslog
  options:
    syslog-address: "tcp://192.168.0.42:123"
```
driver名称指定服务容器的日志记录驱动程序。默认值和可用值是特定于平台的。driver特定的选项可以设置为键值对的选项。

#### network_mode
network_mode 设置服务容器网络模式。可用值是特定于平台的，但 Compose 规范定义了特定值，如果支持，必须按照描述实现这些值： 
  - none 禁用所有容器网络 
  - 主机，它使容器可以原始访问主机的网络接口 
  - service:{name} 只允许容器访问指定的服务
```yml
    network_mode: "host"
    network_mode: "none"
    network_mode: "service:[service name]"
```
#### networks
网络定义了服务容器附加到的网络，引用顶级网络键下的条目。
```yml
services:
  some-service:
    networks:
      - some-network
      - other-network
```
**aliases**
aliases 在网络上声明此服务的备用主机名。同一网络上的其他容器可以使用服务名称或此别名连接到服务的容器之一。 

由于别名是网络范围的，因此相同的服务在不同的网络上可以有不同的别名。 
> 注意：一个网络范围的别名可以被多个容器共享，甚至可以被多个服务共享。如果是，则不能保证名称解析为哪个容器。 

一般格式如下所示：
```yml
services:
  some-service:
    networks:
      some-network:
        aliases:
          - alias1
          - alias3
      other-network:
        aliases:
          - alias2
```
在下面的示例中，服务前端将能够在后端网络上的主机名后端或数据库上访问后端服务，并且服务监控将能够在管理网络上的 db 或 mysql 上访问相同的后端服务。
```yml
services:
  frontend:
    image: awesome/webapp
    networks:
      - front-tier
      - back-tier

  monitoring:
    image: awesome/monitoring
    networks:
      - admin

  backend:
    image: awesome/backend
    networks:
      back-tier:
        aliases:
          - database
      admin:
        aliases:
          - mysql

networks:
  front-tier:
  back-tier:
  admin:
```
**ipv4_address, ipv6_address**
加入网络时，为此服务指定容器的静态 IP 地址。 

顶级网络部分中的相应网络配置必须有一个 ipam 块，其中包含覆盖每个静态地址的子网配置。
```yml
services:
  frontend:
    image: awesome/webapp
    networks:
      front-tier:
        ipv4_address: 172.16.238.10
        ipv6_address: 2001:3984:3989::10

networks:
  front-tier:
    ipam:
      driver: default
      config:
        - subnet: "172.16.238.0/24"
        - subnet: "2001:3984:3989::/64"
```
**link_local_ips**
link_local_ips 指定链接本地 IP 的列表。链路本地 IP 是属于众所周知的子网的特殊 IP，完全由运营商管理，通常取决于部署它们的架构。实现是特定于平台的。

示例：
```yml
services:
  app:
    image: busybox
    command: top
    networks:
      app_net:
        link_local_ips:
          - 57.123.22.11
          - 57.123.22.13
networks:
  app_net:
    driver: bridge
```
**priority**
优先级指示 Compose 实现应该将服务的容器连接到其网络的顺序。如果未指定，则默认值为 0。 

在以下示例中，应用服务首先连接到 app_net_1，因为它具有最高优先级。然后它连接到 app_net_3，然后是 app_net_2，后者使用默认优先级值 0。
```yml
services:
  app:
    image: busybox
    command: top
    networks:
      app_net_1:
        priority: 1000
      app_net_2:

      app_net_3:
        priority: 100
networks:
  app_net_1:
  app_net_2:
  app_net_3:
```

#### mac_address
mac_address 设置服务容器的 MAC 地址。

#### mem_swappiness
mem_swappiness 定义为主机内核换出容器使用的匿名内存页面的百分比（0 到 100 之间的值）。 
 - 值 0 关闭匿名页面交换。 
 - 值为 100 将所有匿名页面设置为可交换的。 

默认值是特定于平台的。

#### memswap_limit
memswap_limit 定义了允许交换到磁盘的内存容器的数量。这是一个修饰符属性，只有在设置了内存时才有意义。使用交换允许容器在容器耗尽所有可用内存时将多余的内存需求写入磁盘。经常将内存交换到磁盘的应用程序会降低性能。 
  - 如果 memswap_limit 设置为正整数，则必须设置 memory 和 memswap_limit。 memswap_limit 表示可以使用的内存和swap总量，memory控制非swap内存使用量。因此，如果 memory="300m" 和 memswap_limit="1g"，则容器可以使用 300m 内存和 700m (1g - 300m) 交换。 
  - 如果 memswap_limit 设置为 0，则必须忽略该设置，并将该值视为未设置。 
  - 如果 memswap_limit 设置为与 memory 相同的值，并且 memory 设置为正整数，则容器无权访问交换。请参阅防止容器使用交换。 
  - 如果未设置 memswap_limit 并设置内存，则容器可以使用与内存设置一样多的交换，如果主机容器配置了交换内存。例如，如果 memory="300m" 和 memswap_limit 未设置，则容器可以使用总共 600m 的内存和交换。 
  - 如果 memswap_limit 显式设置为 -1，则允许容器使用无限交换，最多可达主机系统上可用的数量。

#### oom_kill_disable
如果设置了 oom_kill_disable，Compose 实现必须配置平台，这样它就不会在内存不足的情况下杀死容器。

#### oom_score_adj
oom_score_adj 调整容器在内存不足的情况下被平台杀死的偏好。值必须在 [-1000,1000] 范围内。

#### pid
pid 为 Compose 实现创建的容器设置 PID 模式。支持的值是特定于平台的。
#### pids_limit
pids_limit 调整容器的 PID 限制。对于无限制的 PID，设置为 -1。
```yml
pids_limit: 10
```
#### platform
platform 使用 os[/arch[/variant]] 语法定义了此服务将运行的目标平台容器。 Compose 实现必须在声明时使用此属性来确定将拉取哪个版本的图像和/或将在哪个平台上执行服务的构建。
```yml
platform: osx
platform: windows/amd64
platform: linux/arm64/v8
```
#### ports
暴露容器端口。端口映射不得与 network_mode: host 一起使用，这样做必须导致运行时错误。 

**简短的语法**
简短的语法是一个逗号分隔的字符串，用于以以下形式设置主机 IP、主机端口和容器端口： 
[HOST:]CONTAINER[/PROTOCOL]，其中： 
   - HOST是 [IP:](port | range) 
   - CONTAINER 是port | range 
   - PROTOCOL 将端口限制为指定的协议。 tcp 和 udp 值由规范定义，Compose 实现可以提供对特定于平台的协议名称的支持。 

主机 IP，如果未设置，必须绑定到所有网络接口。端口可以​​是单个值或范围。主机和容器必须使用等效的范围。 

要么指定两个端口 (HOST:CONTAINER)，要么只指定容器端口。在后一种情况下，Compose 实现应该自动分配任何未分配的主机端口。 

HOST:CONTAINER 应始终指定为（带引号的）字符串，以避免与 yaml base-60 浮点数冲突。 

示例：
```yml
ports:
  - "3000"
  - "3000-3005"
  - "8000:8000"
  - "9090-9091:8080-8081"
  - "49100:22"
  - "127.0.0.1:8001:8001"
  - "127.0.0.1:5000-5010:5000-5010"
  - "6060:6060/udp"
```
> 平台上可能不支持主机 IP 映射，在这种情况下，Compose 实现应该拒绝 Compose 文件，并且必须通知用户他们将忽略指定的主机 IP。

**长语法**

长格式语法允许配置不能用短格式表达的附加字段。 
  - target：容器端口 
  - published：公开的端口 
  - host_ip：Host IP 映射，未指定表示所有网络接口（0.0.0.0） 
  - protocol：端口协议（tcp 或 udp），未指定表示任何协议 
  - mode：host 用于在每个节点上发布主机端口，或用于负载均衡的端口的入口。
```yml
ports:
  - target: 80
    host_ip: 127.0.0.1
    published: 8080
    protocol: tcp
    mode: host
```
#### privileged
特权将服务容器配置为以提升的特权运行。支持和实际影响因平台而异。

#### profiles
配置文件定义了要在其下启用的服务的命名配置文件列表。如果未设置，则始终启用服务。 如果存在，配置文件应该遵循 [a-zA-Z0-9][a-zA-Z0-9_.-]+ 的正则表达式格式。

#### pull_policy
pull_policy 定义了 Compose 实现在开始拉取图像时将做出的决定。可能的值为： 
  - always：Compose 实现应该总是从注册表中拉取镜像。 
  - never：Compose 实现不应该从注册表中拉取镜像，并且应该依赖平台缓存的镜像。如果没有缓存图像，则必须报告失败。 
  - missing：仅当平台缓存中不可用时，Compose 实现才应提取图像。这应该是没有构建支持的 Compose 实现的默认选项。为了向后兼容，if_not_present 应该被认为是这个值的别名 
  - build：组合实现应该构建图像。如果已经存在，Compose 实现应该重建图像。 
  
  如果 pull_policy 和 build 都存在，则 Compose 实现应该默认构建镜像。组合实现可能会覆盖工具链中的此行为。

#### read_only
read_only 将服务容器配置为使用只读文件系统创建。

#### restart
restart 定义平台将在容器终止时应用的策略。 
  - no：默认重启策略。在任何情况下都不会重新启动容器。 
  - always：该策略始终重新启动容器，直到将其移除。 
  - on-failure：如果退出代码指示错误，该策略将重新启动容器。 
  - unless-stopped：无论退出代码如何，该策略都会重新启动容器，但会在服务停止或删除时停止重新启动。

```yml
    restart: "no"
    restart: always
    restart: on-failure
    restart: unless-stopped
```
#### runtime
运行时指定用于服务容器的运行时。 运行时的值特定于实现。例如，运行时可以是 OCI 运行时规范的实现名称，例如“runc”。
```yml
web:
  image: busybox:latest
  command: true
  runtime: runc
```
#### secrets
secrets 授予对基于每个服务的 secrets 定义的敏感数据的访问权限。支持两种不同的语法变体：短语法和长语法。 

如果该机密在平台上不存在或未在此 Compose 文件的机密部分中定义，则 Compose 实现必须报告错误。 

**简短的语法** 
简短的语法变体仅指定机密名称。这将授予容器对机密的访问权限，并将其作为只读挂载到容器内的 /run/secrets/<secret_name>。源名称和目标挂载点都设置为机密名称。 

以下示例使用简短语法授予前端服务访问服务器证书密钥的权限。 server-certificate 的值设置为文件 ./server.cert 的内容。
```yml
services:
  frontend:
    image: awesome/webapp
    secrets:
      - server-certificate
secrets:
  server-certificate:
    file: ./server.cert
```
**长语法** 
长语法在如何在服务的容器中创建秘密提供了更多的粒度。 
  - source：存在于平台上的机密名称。 
  - target：要挂载在服务的任务容器中的 /run/secrets/ 中的文件的名称。如果未指定，则默认为 source。 
  - uid 和 gid：在服务的任务容器中拥有 /run/secrets/ 中的文件的数字 UID 或 GID。默认值为 USER 正在运行的容器。 
  - mode：要挂载在服务任务容器中的 /run/secrets/ 中的文件的权限，采用八进制表示法。默认值是全球可读的权限（模式 0444）。如果设置了可写位，则必须忽略。可执行位可以被设置。 
  
下面的例子在容器内将服务器证书机密文件的名称设置为 server.crt，将模式设置为 0440（组可读）并将用户和组设置为 103。服务器证书机密的值由平台通过查找和不由 Compose 实现直接管理的秘密生命周期。
```yml
services:
  frontend:
    image: awesome/webapp
    secrets:
      - source: server-certificate
        target: server.cert
        uid: "103"
        gid: "103"
        mode: 0440
secrets:
  server-certificate:
    external: true
```
服务可以被授予访问多个秘密的权限。秘密的长短语法可以在同一个 Compose 文件中使用。在顶级机密中定义机密 MUTS 并不意味着授予任何服务访问权限。这种授权必须在服务规范中明确作为秘密服务元素。

#### security_opt
security_opt 覆盖每个容器的默认标签方案。
```yml
security_opt:
  - label:user:USER
  - label:role:ROLE
```
#### shm_size
shm_size 配置服务容器允许的共享内存（Linux 上的/dev/shm 分区）的大小。指定为字节值。

#### stdin_open
stdin_open 将服务容器配置为使用分配的 stdin 运行。

#### stop_grace_period
stop_grace_period 指定 Compose 实现在尝试停止容器时必须等待多长时间，如果它不处理 SIGTERM（或使用 stop_signal 指定的任何停止信号），然后发送 SIGKILL。指定为持续时间。
```yml
    stop_grace_period: 1s
    stop_grace_period: 1m30s

```
默认值是容器在发送 SIGKILL 之前退出的 10 秒。

#### stop_signal
stop_signal 定义了 Compose 实现必须用来停止服务容器的信号。如果 Compose 实现通过发送 SIGTERM 停止未设置的容器。
```yml
stop_signal: SIGUSR1
```
#### storage_opt
storage_opt 定义服务的存储驱动程序选项。
```yml
storage_opt:
  size: '1G'
```
#### sysctls
sysctls 定义要在容器中设置的内核参数。 sysctls 可以使用数组或映射。
```yml
sysctls:
  net.core.somaxconn: 1024
  net.ipv4.tcp_syncookies: 0
```
```yml
sysctls:
  - net.core.somaxconn=1024
  - net.ipv4.tcp_syncookies=0
```
您只能使用内核中命名空间的 sysctl。 Docker 不支持在容器内更改 sysctl 也会修改主机系统。有关支持的 sysctls 的概述，请参阅在运行时配置命名空间内核参数 (sysctls)。

#### tmpfs
tmpfs 在容器内挂载一个临时文件系统。可以是单个值或列表。
```yml
tmpfs: /run
```
```yml
tmpfs:
  - /run
  - /tmp
```
#### tty
tty 配置服务容器以与 TTY 一​​起运行。

#### ulimits
ulimits 覆盖容器的默认 ulimits。将单个限制指定为整数或将软/硬限制指定为映射。
```yml
ulimits:
  nproc: 65535
  nofile:
    soft: 20000
    hard: 40000
```
#### user
user 覆盖用于运行容器进程的用户。默认值是由图像（即 Dockerfile USER）设置的，如果未设置，则为 root。

#### userns_mode
userns_mode 设置服务的用户命名空间。支持的值是特定于平台的，可能取决于平台配置
```yml
userns_mode: "host"
```

#### volumes
卷定义了服务容器必须可以访问的挂载主机路径或命名卷。

如果挂载是主机路径并且仅由单个服务使用，则可以将其声明为服务定义的一部分，而不是顶级卷键。 

要在多个服务中重用一个卷，必须在顶级卷键中声明一个命名卷。 

此示例显示后端服务使用的命名卷 (db-data)，以及为单个服务定义的绑定安装
```yml
services:
  backend:
    image: awesome/backend
    volumes:
      - type: volume
        source: db-data
        target: /data
        volume:
          nocopy: true
      - type: bind
        source: /var/run/postgres/postgres.sock
        target: /var/run/postgres/postgres.sock

volumes:
  db-data:
```
**简短的语法** 
简短的语法使用带有逗号分隔值的单个字符串来指定卷安装 (VOLUME:CONTAINER_PATH) 或访问模式 (VOLUME:CONTAINER:ACCESS_MODE)。 

VOLUME 可以是托管容器的平台上的主机路径（绑定安装）或卷名称。 ACCESS_MODE 可以使用 ro 设置为只读或使用 rw（默认）进行读写。 .

> 注意：相对主机路径必须仅由部署到本地容器运行时的 Compose 实现支持。这是因为相对路径是从 Compose 文件的父目录解析的，这仅适用于本地情况。部署到非本地平台的 Compose 实现必须拒绝使用相关主机路径的 Compose 文件并出现错误。为了避免命名卷的歧义，相对路径应该总是以 .或者 ... 

**长语法** 
长格式语法允许配置不能用短格式表达的附加字段。 
  - type：安装类型卷、绑定、tmpfs 或 npipe 
  - source：安装的来源，主机上用于绑定安装的路径，或在顶级卷键中定义的卷的名称。不适用于 tmpfs 挂载。 
  - target：安装卷的容器中的路径 
  - read_only: 将卷设置为只读的标志 
  - bind：配置额外的绑定选项 
    - propagation：用于绑定的传播模式 
    - create_host_path：如果没有任何内容，则在主机上的源路径上创建一个目录。如果路径上有东西，什么都不做。这由简短的语法自动暗示，以便与 d​​ocker-compose legacy 向后兼容。 
  - volume：配置额外的音量选项 
    - nocopy：在创建卷时禁用从容器复制数据的标志 
  - tmpfs：配置额外的 tmpfs 选项 
    - size：tmpfs 挂载的大小（以字节为单位） 
  - consistency：挂载的一致性要求。可用值是特定于平台的

#### volumes_from
volumes_from 挂载来自另一个服务或容器的所有卷，可选择指定只读访问 (ro) 或读写 (rw)。如果未指定访问级别，则必须使用读写。 字符串值定义了 Compose 应用程序模型中的另一个服务来装载卷。 container: 前缀（如果支持）允许从不受 Compose 实现管理的容器挂载卷。
```yml
volumes_from:
  - service_name
  - service_name:ro
  - container:container_name
  - container:container_name:rw
```
#### working_dir
working_dir 从镜像指定的目录（即 Dockerfile WORKDIR）覆盖容器的工作目录。















