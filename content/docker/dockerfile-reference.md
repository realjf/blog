---
title: "Dockerfile手册 Dockerfile Reference"
date: 2021-06-07T09:09:23+08:00
keywords: ["docker", "dockerfile"]
categories: ["docker"]
tags: ["docker", "dockerfile"]
series: [""]
draft: false
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

### .dockerignore 文件

```dockerignore
# comment
*/temp*
*/*/temp*
temp?
```
| 规则 | 行为 |
|-----| ------|
| # comment | 忽略 |
| */temp * | 排除以temp开头的文件和当前目录的子目录，如：/somedir/temporary.txt |
| * / * /temp* | 排除以temp开头的文件和两级子目录，如：/somedir/subdir/temporary.txt |
| temp ? | 排除以temp扩展一个字母的文件和目录，如：/tempa,tempb等 |


### FROM
```dockerfile
FROM [--platform=<platform>] <image> [AS <name>]
# or
FROM [--platform=<platform>] <image>[:<tag>] [AS <name>]
# or
FROM [--platform=<platform>] <image>[@<digest>] [AS <name>]
```
FROM 指令初始化一个新的构建阶段并为后续指令设置基础镜像。因此，有效的 Dockerfile 必须以 FROM 指令开头。镜像可以是任何有效的镜像——从公共存储库中提取镜像特别容易。 

- ARG 是 Dockerfile 中可能位于 FROM 之前的唯一指令。请参阅了解 ARG 和 FROM 如何交互。 
- FROM 可以在单个 Dockerfile 中多次出现以创建多个镜像或使用一个构建阶段作为另一个构建阶段的依赖项。只需记下每个新 FROM 指令之前提交的最后一个镜像 ID 输出。每个 FROM 指令都会清除由先前指令创建的任何状态。 
- 可以选择通过将 AS name 添加到 FROM 指令来为新的构建阶段指定名称。该名称可用于后续的 FROM 和 COPY --from=<name> 指令以引用在此阶段构建的映像。 
- tag 或 digest 值是可选的。如果您省略其中任何一个，构建器默认采用 latest 标签。如果构建器找不到标签值，它会返回一个错误。 

可选的 --platform 标志可用于在 FROM 引用多平台图像的情况下指定图像的平台。例如，linux/amd64、linux/arm64 或 windows/amd64。默认情况下，使用构建请求的目标平台。全局构建参数可用于此标志的值，例如自动平台 ARG 允许您强制一个阶段到本机构建平台（--platform=$BUILDPLATFORM），并使用它交叉编译到内部的目标平台阶段。

**理解ARG 和 FROM 如何交互**

FROM指令支持由在第一个FROM指令之前出现的任何ARG指令声明的变量
```dockerfile
ARG  CODE_VERSION=latest
FROM base:${CODE_VERSION}
CMD  /code/run-app

FROM extras:${CODE_VERSION}
CMD  /code/run-extras
```
在 FROM 之前声明的 ARG 在构建阶段之外，因此不能在 FROM 之后的任何指令中使用。要使用在第一个 FROM 之前声明的 ARG 的默认值，请使用在构建阶段内没有值的 ARG 指令：
```dockerfile
ARG VERSION=latest
FROM busybox:$VERSION
ARG VERSION
RUN echo $VERSION > image_version
```

### RUN
RUN 有2种格式：

- RUN <command> shell 形式，命令在 shell 中运行，Linux 上默认为 /bin/sh -c 或 Windows 上 cmd /S /C
- RUN ["executable", "param1", "param2"] exec格式

RUN 指令将在当前图像之上的新层中执行任何命令并提交结果。生成的提交映像将用于 Dockerfile 中的下一步。 

分层 RUN 指令和生成提交符合 Docker 的核心概念，其中提交成本低，并且可以从镜像历史中的任何点创建容器，就像源代码控制一样。 

exec 形式可以避免 shell 字符串修改，并可以使用不包含指定 shell 可执行文件的基本映像来运行命令。 可以使用 SHELL 命令更改 shell 格式的默认 shell

在 shell 形式中，您可以使用 \（反斜杠）将单个 RUN 指令延续到下一行。例如，考虑以下两行：
```dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc; \
echo $HOME'
```
它们一起相当于这一行：
```dockerfile
RUN /bin/bash -c 'source $HOME/.bashrc; echo $HOME'
```
使用不同的 shell，而不是‘/bin/sh’，使用传入所需 shell 的 exec 形式。例如：
```dockerfile
RUN ["/bin/bash", "-c", "echo hello"]
```
> exec 形式被解析为一个 JSON 数组，这意味着您必须在单词周围使用双引号 (“) 而不是单引号 (‘)。

与 shell 形式不同，exec 形式不调用命令 shell。这意味着不会发生正常的 shell 处理。例如， RUN [ "echo", "$HOME" ] 不会对 $HOME 进行变量替换。如果你想要 shell 处理，那么要么使用 shell 形式，要么直接执行 shell，例如：RUN [ "sh", "-c", "echo $HOME" ]。当使用 exec 形式并直接执行 shell 时，就像 shell 形式一样，是 shell 进行环境变量扩展，而不是 docker。

> 在 JSON 形式中，需要转义反斜杠。这在反斜杠是路径分隔符的 Windows 上尤其重要。由于不是有效的 JSON，以下行将被视为 shell 形式，并以意想不到的方式失败：
>  ```dockerfile
>  RUN ["c:\windows\system32\tasklist.exe"]
>  ```
> 此示例的正确语法是
> ```dockerfile
> RUN ["c:\\windows\\system32\\tasklist.exe"]
> ```

在下一次构建期间，RUN 指令的缓存不会自动失效。像 RUN apt-get dist-upgrade -y 这样的指令的缓存将在下一次构建期间重用。可以使用 --no-cache 标志使 RUN 指令的缓存失效，例如 docker build --no-cache。 

有关更多信息，请参阅 Dockerfile 最佳实践指南。 
RUN 指令的缓存可以通过 ADD 和 COPY 指令失效。

### CMD
CMD指令有三种格式：

- CMD ["executable","param1","param2"] exec格式，推荐格式
- CMD ["param1","param2"] 作为 ENTRYPOINT 的默认参数
- CMD command param1 param2 shell格式

一个 Dockerfile 中只能有一个 CMD 指令。如果你列出了多个 CMD，那么只有最后一个 CMD 会生效。 

CMD 的主要目的是为正在执行的容器提供默认值。这些默认值可以包含可执行文件，也可以省略可执行文件，在这种情况下，您还必须指定 ENTRYPOINT 指令。 

如果 CMD 用于为 ENTRYPOINT 指令提供默认参数，则应使用 JSON 数组格式指定 CMD 和 ENTRYPOINT 指令。

> exec 形式被解析为一个 JSON 数组，这意味着您必须在单词周围使用双引号 (“) 而不是单引号 (‘)。

与 shell 形式不同，exec 形式不调用命令 shell。这意味着不会发生正常的 shell 处理。例如， CMD [ "echo", "$HOME" ] 不会对 $HOME 进行变量替换。如果你想要 shell 处理，那么要么使用 shell 形式，要么直接执行 shell，例如：CMD [ "sh", "-c", "echo $HOME" ]。

当使用 exec 形式并直接执行 shell 时，就像 shell 形式一样，是 shell 进行环境变量扩展，而不是 docker。 在 shell 或 exec 格式中使用时，CMD 指令设置运行图像时要执行的命令。 

如果使用 CMD 的 shell 形式，则 <command> 将在 /bin/sh -c 中执行：
```dockerfile
FROM ubuntu
CMD echo "This is a test." | wc -
```
如果您想在没有 shell 的情况下运行 <command>，那么您必须将命令表示为 JSON 数组并提供可执行文件的完整路径。这种数组形式是 CMD 的首选格式。任何附加参数都必须单独表示为数组中的字符串：
```dockerfile
FROM ubuntu
CMD ["/usr/bin/wc","--help"]
```
如果您希望容器每次都运行相同的可执行文件，那么您应该考虑将 ENTRYPOINT 与 CMD 结合使用。请参阅 ENTRYPOINT。 

如果用户为 docker run 指定参数，则它们将覆盖 CMD 中指定的默认值。

> 不要将 RUN 与 CMD 混淆。 RUN 实际运行一个命令并提交结果； CMD 在构建时不执行任何操作，而是指定映像的预期命令。


### LABEL
```dockerfile
LABEL <key>=<value> <key>=<value> <key>=<value> ...
```
LABEL 指令向镜像添加元数据。 LABEL 是键值对。要在 LABEL 值中包含空格，请像在命令行解析中一样使用引号和反斜杠。几个使用示例：
```dockerfile
LABEL "com.example.vendor"="ACME Incorporated"
LABEL com.example.label-with-value="foo"
LABEL version="1.0"
LABEL description="This text illustrates \
that label-values can span multiple lines."
```
一个镜像可以有多个标签。可以在一行上指定多个标签。在Docker1.10之前，这减小了最终镜像的大小，但现在不再是这样了。您仍然可以选择通过以下两种方式之一在一条指令中指定多个标签：
```dockerfile
# 方式一
LABEL multi.label1="value1" multi.label2="value2" other="value3"
# 方式二
LABEL multi.label1="value1" \
      multi.label2="value2" \
      other="value3"
```
基础镜像或父镜像（FROM行中的镜像）中包含的标签由镜像继承。如果标签已存在但具有不同的值，则最近应用的值将覆盖任何先前设置的值。

要查看镜像的标签，请使用docker image inspect命令。您可以使用--format选项只显示标签；
```sh
docker image inspect --format='' myimage

{
  "com.example.vendor": "ACME Incorporated",
  "com.example.label-with-value": "foo",
  "version": "1.0",
  "description": "This text illustrates that label-values can span multiple lines.",
  "multi.label1": "value1",
  "multi.label2": "value2",
  "other": "value3"
}
```
### MAINTAINER [已弃用]

MAINTAINER指令设置生成镜像的Author字段。LABEL指令是一个更灵活的版本，您应该改用它，因为它允许设置您需要的任何元数据，并且可以很容易地查看，例如使用docker inspect。要设置与MAINTAINER字段相对应的标签，可以使用：
```dockerfile
LABEL org.opencontainers.image.authors="SvenDowideit@home.org.au"
```

### EXPOSE
```dockerfile
EXPOSE <port> [<port>/<protocol>...]
```
EXPOSE 指令通知 Docker 容器在运行时监听指定的网络端口。可以指定端口是监听TCP还是UDP，如果不指定协议，默认为TCP。

EXPOSE 指令实际上并不发布端口。它充当构建镜像的人和运行容器的人之间的一种文档，关于打算发布哪些端口。要在运行容器时实际发布端口，请在 docker run 上使用 -p 标志发布和映射一个或多个端口，或使用 -P 标志发布所有暴露的端口并将它们映射到高阶端口。 

默认情况下，EXPOSE 假定 TCP。您还可以指定 UDP：
```dockerfile
EXPOSE 80/udp
```
要同时在 TCP 和 UDP 上公开，请包含两行：
```dockerfile
EXPOSE 80/tcp
EXPOSE 80/udp
```
在这种情况下，如果您将 -P 与 docker run 一起使用，则端口将为 TCP 公开一次，为 UDP 公开一次。请记住，-P 使用主机上的临时高阶主机端口，因此 TCP 和 UDP 的端口将不同。 

无论 EXPOSE 设置如何，您都可以在运行时使用 -p 标志覆盖它们。例如
```sh
docker run -p 80:80/tcp -p 80:80/udp ...
```
要在主机系统上设置端口重定向，请参阅使用 -P 标志。 docker network 命令支持创建用于容器间通信的网络，而无需公开或发布特定端口，因为连接到网络的容器可以通过任何端口相互通信。有关详细信息，请参阅此功能的概述。

### ENV
```dockerfile
ENV <key>=<value> ...
```
ENV 指令将环境变量 <key> 设置为值 <value>。此值将在构建阶段的所有后续指令的环境中，并且也可以在许多中内联替换。该值将被解释为其他环境变量，因此如果没有转义引号字符将被删除。与命令行解析一样，引号和反斜杠可用于在值中包含空格。

例如：
```dockerfile
ENV MY_NAME="John Doe"
ENV MY_DOG=Rex\ The\ Dog
ENV MY_CAT=fluffy
```
ENV 指令允许一次设置多个 <key>=<value> ... 变量，下面的示例将在最终镜像中产生相同的净结果：
```dockerfile
ENV MY_NAME="John Doe" MY_DOG=Rex\ The\ Dog \
    MY_CAT=fluffy
```
当容器从生成的镜像运行时，使用 ENV 设置的环境变量将持续存在。您可以使用 docker inspect 查看值，并使用 docker run --env <key>=<value> 更改它们。 

环境变量持久性可能会导致意外的副作用。例如，设置 ENV DEBIAN_FRONTEND=noninteractive 会更改 apt-get 的行为，并且可能会使用户对您的镜像感到困惑。 

如果仅在构建期间需要环境变量，而不是在最终镜像中，请考虑为单个命令设置一个值：
```dockerfile
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y ...
```
或者使用 ARG，它不会保留在最终镜像中
```dockerfile
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ...
```
> 替代语法
> ENV 指令还允许替代语法 ENV <key> <value>，省略 =。例如：
> ```dockerfile
> ENV MY_VAR my-value
> ```
> 此语法不允许在单个 ENV 指令中设置多个环境变量，并且可能会造成混淆。例如，以下设置了一个值为“TWO= THREE=world”的单个环境变量 (ONE)：
> ```dockerfile
> ENV ONE TWO= THREE=world
> ```
> 支持替代语法以实现向后兼容性，但由于上述原因不鼓励使用，并且可能会在未来版本中删除。


### ADD
ADD有两种形式
```dockerfile
ADD [--chown=<user>:<group>] <src>... <dest>
ADD [--chown=<user>:<group>] ["<src>",... "<dest>"]
```
包含空格的路径需要后一种形式。
> --chown 功能仅在用于构建 Linux 容器的 Dockerfile 上受支持，不适用于 Windows 容器。由于用户和组所有权概念不会在 Linux 和 Windows 之间转换，因此使用 /etc/passwd 和 /etc/group 将用户和组名称转换为 ID 限制了此功能仅适用于基于 Linux 操作系统的容器。

ADD 指令从 <src> 复制新文件、目录或远程文件 URL，并将它们添加到路径 <dest> 处的镜像文件系统。 
可以指定多个 <src> 资源，但如果它们是文件或目录，则它们的路径被解释为相对于构建上下文的源。 
每个 <src> 可能包含通配符，匹配将使用 Go 的 filepath.Match 规则完成。例如： 添加所有以“hom”开头的文件：
```dockerfile
ADD hom* /mydir/
```
在下面的例子中，?被任何单个字符替换，例如“home.txt”。
```dockerfile
ADD hom?.txt /mydir/
```
<dest> 是绝对路径，或相对于 WORKDIR 的路径，将源复制到目标容器内该路径中。 下面的示例使用相对路径，并将“test.txt”添加到 <WORKDIR>/relativeDir/：

```dockerfile
ADD test.txt relativeDir/
```
而此示例使用绝对路径，并将“test.txt”添加到 /absoluteDir/
```dockerfile
ADD test.txt /absoluteDir/
```
添加包含特殊字符（例如 [ 和 ]）的文件或目录时，您需要按照 Golang 规则对这些路径进行转义，以防止它们被视为匹配模式。例如，要添加名为 arr[0].txt 的文件，请使用以下命令；

```dockerfile
ADD arr[[]0].txt /mydir/
```
所有新文件和目录都使用 0 的 UID 和 GID 创建，除非可选的 --chown 标志指定给定的用户名、组名或 UID/GID 组合来请求添加内容的特定所有权。 --chown 标志的格式允许用户名和组名字符串或直接整数 UID 和 GID 的任意组合。提供不带组名的用户名或不带 GID 的 UID 将使用与 GID 相同的数字 UID。如果提供了用户名或组名，则容器的根文件系统 /etc/passwd 和 /etc/group 文件将分别用于执行从名称到整数 UID 或 GID 的转换。以下示例显示了 --chown 标志的有效定义：
```dockerfile
ADD --chown=55:mygroup files* /somedir/
ADD --chown=bin files* /somedir/
ADD --chown=1 files* /somedir/
ADD --chown=10:11 files* /somedir/
```
如果容器根文件系统不包含 /etc/passwd 或 /etc/group 文件，并且在 --chown 标志中使用了用户名或组名，则在执行 ADD 操作时构建将失败。使用数字 ID 不需要查找，也不依赖于容器根文件系统内容。 
在 <src> 是远程文件 URL 的情况下，目标将具有 600 的权限。如果正在检索的远程文件具有 HTTP Last-Modified 标头，则该标头中的时间戳将用于设置目标上的 mtime文件。但是，与在 ADD 期间处理的任何其他文件一样，在确定文件是否已更改以及是否应更新缓存时，将不包括 mtime。

> 如果通过 STDIN (docker build - < somefile) 传递 Dockerfile 进行构建，则没有构建上下文，因此 Dockerfile 只能包含基于 URL 的 ADD 指令。您还可以通过 STDIN 传递压缩存档：(docker build - < archive.tar.gz)，存档根目录下的 Dockerfile 和存档的其余部分将用作构建的上下文。

如果您的 URL 文件使用身份验证保护，则需要使用 RUN wget、RUN curl 或使用容器内的其他工具，因为 ADD 指令不支持身份验证。

> 如果 <src> 的内容发生变化，第一个遇到的 ADD 指令将使来自 Dockerfile 的所有后续指令的缓存无效。这包括使 RUN 指令的缓存无效。有关详细信息，请参阅 Dockerfile 最佳实践指南 - 利用构建缓存。

ADD 遵循以下规则： 
- <src> 路径必须在构建的上下文中；您不能添加 ../something /something，因为 docker 构建的第一步是将上下文目录（和子目录）发送到 docker 守护进程。 
- 如果 <src> 是一个 URL 并且 <dest> 不以斜杠结尾，那么文件将从 URL 下载并复制到 <dest>。 
- 如果 <src> 是一个 URL 并且 <dest> 确实以斜杠结尾，则从 URL 推断文件名并将文件下载到 <dest>/<filename>。例如，添加 http://example.com/foobar / 将创建文件 /foobar。 URL 必须有一个重要的路径，以便在这种情况下可以发现适当的文件名（http://example.com 将不起作用）。 
- 如果 <src> 是目录，则复制目录的全部内容，包括文件系统元数据。

> 不会复制目录本身，只会复制其内容。

- 如果 <src> 是采用可识别压缩格式（identity、gzip、bzip2 或 xz）的本地 tar 存档，则将其解压缩为目录。来自远程 URL 的资源不会被解压缩。当一个目录被复制或解压时，它的行为与 tar -x 相同，结果是： 
  - 目标路径中存在的任何内容和 
  - 源树的内容，解决了有利于“2”的冲突。在逐个文件的基础上。

> 文件是否被识别为可识别的压缩格式完全取决于文件的内容，而不是文件的名称。例如，如果一个空文件恰好以 .tar.gz 结尾，这将不会被识别为压缩文件，也不会生成任何类型的解压缩错误消息，而只会将该文件复制到目标位置。

- 如果 <src> 是任何其他类型的文件，则将其与其元数据一起单独复制。在这种情况下，如果 <dest> 以斜杠 / 结尾，它将被视为一个目录，并且 <src> 的内容将写入 <dest>/base(<src>)。 
- 如果直接指定了多个 <src> 资源，或者由于使用了通配符，则 <dest> 必须是一个目录，并且必须以斜杠 / 结尾。 
- 如果 <dest> 不以斜杠结尾，它将被视为一个普通文件，并且 <src> 的内容将写入 <dest>。 
- 如果 <dest> 不存在，它会与路径中所有缺失的目录一起创建。

### COPY
COPY有两种形式：
```dockerfile
COPY [--chown=<user>:<group>] <src>... <dest>
COPY [--chown=<user>:<group>] ["<src>",... "<dest>"]
```
包含空格的路径需要后一种形式

> --chown特性仅在用于构建Linux容器的Dockerfiles上受支持，在Windows容器上不起作用。由于用户和组所有权概念不会在Linux和Windows之间转换，因此使用/etc/passwd和/etc/group将用户名和组名转换为id将限制此功能仅适用于基于Linux操作系统的容器。

COPY 指令从 <src> 复制新文件或目录，并将它们添加到路径 <dest> 处的容器文件系统中。 可以指定多个 <src> 资源，但文件和目录的路径将被解释为相对于构建上下文的源。 

每个 <src> 可能包含通配符，匹配将使用 Go 的 filepath.Match 规则完成。例如： 
添加所有以“hom”开头的文件：
```dockerfile
COPY hom* /mydir/
```
在下面的例子中，?被任何单个字符替换，例如“home.txt”。
```dockerfile
COPY hom?.txt /mydir/
```
<dest> 是绝对路径，或相对于 WORKDIR 的路径，将源复制到目标容器内该路径中。 下面的示例使用相对路径，并将“test.txt”添加到 <WORKDIR>/relativeDir/：

```dockerfile
COPY test.txt relativeDir/
```
而此示例使用绝对路径，并将“test.txt”添加到 /absoluteDir/
```dockerfile
COPY test.txt /absoluteDir/
```
添加包含特殊字符（例如 [ 和 ]）的文件或目录时，您需要按照 Golang 规则对这些路径进行转义，以防止它们被视为匹配模式。例如，要添加名为 arr[0].txt 的文件，请使用以下命令；

```dockerfile
COPY arr[[]0].txt /mydir/
```
所有新文件和目录都使用 0 的 UID 和 GID 创建，除非可选的 --chown 标志指定给定的用户名、组名或 UID/GID 组合以请求复制内容的特定所有权。 --chown 标志的格式允许用户名和组名字符串或直接整数 UID 和 GID 的任意组合。提供不带组名的用户名或不带 GID 的 UID 将使用与 GID 相同的数字 UID。如果提供了用户名或组名，则容器的根文件系统 /etc/passwd 和 /etc/group 文件将分别用于执行从名称到整数 UID 或 GID 的转换。以下示例显示了 --chown 标志的有效定义：
```dockerfile
COPY --chown=55:mygroup files* /somedir/
COPY --chown=bin files* /somedir/
COPY --chown=1 files* /somedir/
COPY --chown=10:11 files* /somedir/
```
如果容器根文件系统不包含 /etc/passwd 或 /etc/group 文件，并且在 --chown 标志中使用了用户名或组名，则构建将在 COPY 操作中失败。使用数字 ID 不需要查找，也不依赖于容器根文件系统内容

> 如果使用 STDIN (docker build - < somefile) 构建，则没有构建上下文，因此无法使用 COPY。

COPY 可以选择接受一个标志 --from=<name> ，该标志可用于将源位置设置为先前的构建阶段（使用 FROM .. AS <name> 创建），该阶段将用于代替用户发送的构建上下文.如果无法找到具有指定名称的构建阶段，则会尝试使用具有相同名称的镜像。 

COPY 遵循以下规则： 
- <src> 路径必须在构建的上下文中；您不能 COPY ../something /something，因为 docker 构建的第一步是将上下文目录（和子目录）发送到 docker 守护进程。 
- 如果 <src> 是目录，则复制目录的全部内容，包括文件系统元数据。

> 不会复制目录本身，只会复制其内容。

- 如果 <src> 是任何其他类型的文件，则将其与其元数据一起单独复制。在这种情况下，如果 <dest> 以斜杠 / 结尾，它将被视为一个目录，并且 <src> 的内容将写入 <dest>/base(<src>)。 
- 如果直接指定了多个 <src> 资源，或者由于使用了通配符，则 <dest> 必须是一个目录，并且必须以斜杠 / 结尾。 
- 如果 <dest> 不以斜杠结尾，它将被视为一个普通文件，并且 <src> 的内容将写入 <dest>。 
- 如果 <dest> 不存在，它会与路径中所有缺失的目录一起创建。

### ENTRYPOINT
有两种形式
```dockerfile
# 推荐形式
ENTRYPOINT ["executable", "param1", "param2"]
# shell 形式
ENTRYPOINT command param1 param2
```
ENTRYPOINT 允许您配置将作为可执行文件运行的容器。 
例如，以下内容以默认内容启动 nginx，侦听端口 80：
```sh
docker run -i -t --rm -p 80:80 nginx
```
docker run <image> 的命令行参数将附加在 exec 形式的 ENTRYPOINT 中的所有元素之后，并将覆盖使用 CMD 指定的所有元素。这允许将参数传递给入口点，即 docker run <image> -d 会将 -d 参数传递给入口点。您可以使用 docker run --entrypoint 标志覆盖 ENTRYPOINT 指令。 

shell 形式可防止使用任何 CMD 或运行命令行参数，但缺点是您的 ENTRYPOINT 将作为 /bin/sh -c 的子命令启动，它不传递信号。这意味着可执行文件不会是容器的 PID 1 - 并且不会接收 Unix 信号 - 因此您的可执行文件不会从 docker stop <container> 收到 SIGTERM。 

只有 Dockerfile 中的最后一条 ENTRYPOINT 指令会起作用。

**Exec 形式 ENTRYPOINT 示例**

您可以使用 ENTRYPOINT 的 exec 形式来设置相当稳定的默认命令和参数，然后使用任一形式的 CMD 来设置更可能更改的其他默认值。
```dockerfile
FROM ubuntu
ENTRYPOINT ["top", "-b"]
CMD ["-c"]
```
当你运行容器时，你可以看到 top 是唯一的进程：
```sh
docker run -it --rm --name test  top -H
```
要进一步检查结果，您可以使用 docker exec：
```sh
docker exec -it test ps aux
```
您可以使用 docker stop test 优雅地请求 top 关闭。 
以下 Dockerfile 显示了使用 ENTRYPOINT 在前台运行 Apache（即，作为 PID 1）
```dockerfile
FROM debian:stable
RUN apt-get update && apt-get install -y --force-yes apache2
EXPOSE 80 443
VOLUME ["/var/www", "/var/log/apache2", "/etc/apache2"]
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
```
如果您需要为单个可执行文件编写启动脚本，您可以使用 exec 和 gosu 命令确保最终的可执行文件接收到 Unix 信号
```sh
#!/usr/bin/env bash
set -e

if [ "$1" = 'postgres' ]; then
    chown -R postgres "$PGDATA"

    if [ -z "$(ls -A "$PGDATA")" ]; then
        gosu postgres initdb
    fi

    exec gosu postgres "$@"
fi

exec "$@"
```
最后，如果您需要在关闭时进行一些额外的清理（或与其他容器通信），或者正在协调多个可执行文件，您可能需要确保 ENTRYPOINT 脚本接收 Unix 信号，将它们传递，然后做一些更多的工作：
```sh
#!/bin/sh
# Note: I've written this using sh so it works in the busybox container too

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "echo TRAPed signal" HUP INT QUIT TERM

# start service in background here
/usr/sbin/apachectl start

echo "[hit enter key to exit] or run 'docker stop <container>'"
read

# stop service and clean up here
echo "stopping apache"
/usr/sbin/apachectl stop

echo "exited $0"
```
如果您使用 docker run -it --rm -p 80:80 --name test apache 运行此映像，则可以使用 docker exec 或 docker top 检查容器的进程，然后要求脚本停止 Apache：
```sh
 docker exec -it test ps aux
```
> 您可以使用 --entrypoint 覆盖 ENTRYPOINT 设置，但这只能将二进制文件设置为 exec（不会使用 sh -c）。

> exec 形式被解析为一个 JSON 数组，这意味着您必须在单词周围使用双引号 (“) 而不是单引号 (‘)。

与 shell 形式不同，exec 形式不调用命令 shell。这意味着不会发生正常的 shell 处理。例如， ENTRYPOINT [ "echo", "$HOME" ] 不会对 $HOME 进行变量替换。如果你想要 shell 处理，那么要么使用 shell 形式，要么直接执行 shell，例如：ENTRYPOINT [ "sh", "-c", "echo $HOME" ]。当使用 exec 形式并直接执行 shell 时，就像 shell 形式一样，是 shell 进行环境变量扩展，而不是 docker。

**Shell 形式 ENTRYPOINT 示例**

您可以为 ENTRYPOINT 指定一个纯字符串，它将在 /bin/sh -c 中执行。此表单将使用 shell 处理来替换 shell 环境变量，并将忽略任何 CMD 或 docker run 命令行参数。为了确保 docker stop 能够正确地向任何长时间运行的 ENTRYPOINT 可执行文件发出信号，您需要记住用 exec 启动它：
```dockerfile
FROM ubuntu
ENTRYPOINT exec top -b
```
运行此映像时，您将看到单个 PID 1 进程：
```sh
docker run -it --rm --name test top
```
在 docker stop 上干净地退出：
```sh
 /usr/bin/time docker stop test
```
如果您忘记将 exec 添加到 ENTRYPOINT 的开头：
```dockerfile
FROM ubuntu
ENTRYPOINT top -b
CMD --ignored-param1
```
然后您可以运行它（为下一步命名）：
```sh
docker run -it --name test top --ignored-param2
```
您可以从 top 的输出中看到指定的 ENTRYPOINT 不是 PID 1。 如果您然后运行 ​​docker stop test，容器将不会干净地退出 - stop 命令将在超时后强制发送 SIGKILL：

**了解 CMD 和 ENTRYPOINT 如何交互**
CMD 和 ENTRYPOINT 指令都定义了运行容器时执行的命令。很少有规则可以描述他们的合作。    
  - Dockerfile 应至少指定 CMD 或 ENTRYPOINT 命令之一。 
  - 将容器用作可执行文件时，应定义 ENTRYPOINT。 
  - CMD 应该用作定义 ENTRYPOINT 命令或在容器中执行 ad-hoc 命令的默认参数的一种方式。 
  - 使用替代参数运行容器时，CMD 将被覆盖。 
  
下表显示了针对不同的 ENTRYPOINT / CMD 组合执行的命令：

|	|No ENTRYPOINT|	ENTRYPOINT exec_entry p1_entry	|ENTRYPOINT [“exec_entry”, “p1_entry”] |
|-----|-----|-----|-----|
|No CMD|	error, not allowed|	/bin/sh -c exec_entry p1_entry|	exec_entry p1_entry|
|CMD [“exec_cmd”, “p1_cmd”]	|exec_cmd p1_cmd	|/bin/sh -c exec_entry p1_entry|	exec_entry p1_entry exec_cmd p1_cmd|
|CMD [“p1_cmd”, “p2_cmd”]	|p1_cmd p2_cmd|	/bin/sh -c exec_entry p1_entry|	exec_entry p1_entry p1_cmd p2_cmd|
|CMD exec_cmd p1_cmd|	/bin/sh -c exec_cmd p1_cmd	|/bin/sh -c exec_entry p1_entry|	exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd|

如果 CMD 是从基础映像定义的，则设置 ENTRYPOINT 会将 CMD 重置为空值。在这种情况下，必须在当前镜像中定义 CMD 才能具有值。

### VOLUME
```dockerfile
VOLUME ["/data"]
```
VOLUME 指令创建一个具有指定名称的挂载点，并将其标记为保存来自本机主机或其他容器的外部挂载卷。该值可以是 JSON 数组、VOLUME ["/var/log/"] 或带有多个参数的纯字符串，例如 VOLUME /var/log 或 VOLUME /var/log /var/db。有关通过 Docker 客户端的更多信息/示例和安装说明，请参阅通过卷文档共享目录。 

docker run 命令使用基础映像中指定位置存在的任何数据初始化新创建的卷。例如，考虑以下 Dockerfile 片段：
```dockerfile
FROM ubuntu
RUN mkdir /myvol
RUN echo "hello world" > /myvol/greeting
VOLUME /myvol
```
此 Dockerfile 生成的映像会导致 docker run 在 /myvol 创建新的挂载点，并将greeting文件复制到新创建的卷中。

**关于指定卷的注意事项**

请记住以下有关 Dockerfile 中的卷的事项。 
  - 基于 Windows 的容器上的卷：使用基于 Windows 的容器时，容器内卷的目标必须是以下之一： 
    - 一个不存在或空的目录 
    - C: 以外的驱动器 
  - 从 Dockerfile 中更改卷：如果任何构建步骤在声明卷后更改了卷中的数据，则这些更改将被丢弃。 
  - JSON 格式：列表被解析为 JSON 数组。您必须用双引号 (") 而不是单引号 (') 将单词括起来。 
  - 主机目录在容器运行时声明：主机目录（挂载点）本质上是依赖于主机的。这是为了保持图像的可移植性，因为不能保证给定的主机目录在所有主机上都可用。因此，您无法从 Dockerfile 中挂载主机目录。 VOLUME 指令不支持指定主机目录参数。您必须在创建或运行容器时指定挂载点。

### USER
```dockerfile
USER <user>[:<group>]
# or
USER <UID>[:<GID>]
```
USER 指令设置用户名（或 UID）和可选的用户组（或 GID）以在运行映像时使用，以及在 Dockerfile 中跟随它的任何 RUN、CMD 和 ENTRYPOINT 指令。

> 请注意，为用户指定组时，用户将仅具有指定的组成员资格。任何其他配置的组成员资格都将被忽略。

> 当用户没有主组时，映像（或下一个指令）将与根组一起运行。 在 Windows 上，如果用户不是内置帐户，则必须先创建该用户。这可以通过作为 Dockerfile 的一部分调用的 net user 命令来完成。

```dockerfile
FROM microsoft/windowsservercore
# Create Windows user in the container
RUN net user /add patrick
# Set it for subsequent commands
USER patrick
```

### WORKDIR
```dockerfile
WORKDIR /path/to/workdir
```
WORKDIR 指令为 Dockerfile 中跟随它的任何 RUN、CMD、ENTRYPOINT、COPY 和 ADD 指令设置工作目录。如果 WORKDIR 不存在，即使它没有在任何后续 Dockerfile 指令中使用，它也会被创建。 

WORKDIR 指令可以在 Dockerfile 中多次使用。如果提供了相对路径，它将相对于前一个 WORKDIR 指令的路径。例如：
```dockerfile
WORKDIR /a
WORKDIR b
WORKDIR c
RUN pwd
```
此 Dockerfile 中的最终 pwd 命令的输出将是 /a/b/c。 WORKDIR 指令可以解析先前使用 ENV 设置的环境变量。您只能使用在 Dockerfile 中显式设置的环境变量。例如：
```dockerfile
ENV DIRPATH=/path
WORKDIR $DIRPATH/$DIRNAME
RUN pwd
```
此 Dockerfile 中最终 pwd 命令的输出将是 /path/$DIRNAME

### ARG
```dockerfile
ARG <name>[=<default value>]
```
ARG 指令定义了一个变量，用户可以在构建时使用 --build-arg <varname>=<value> 标志使用 docker build 命令将其传递给构建器。如果用户指定了未在 Dockerfile 中定义的构建参数，则构建会输出警告。

一个 Dockerfile 可能包含一个或多个 ARG 指令。例如，以下是一个有效的 Dockerfile：
```dockerfile
FROM busybox
ARG user1
ARG buildno
# ...
```
**默认值**
```dockerfile
FROM busybox
ARG user1=someuser
ARG buildno=1
# ...
```
如果 ARG 指令具有默认值并且在构建时没有传递任何值，则构建器将使用默认值。

**范围**
ARG 变量定义从它在 Dockerfile 中定义的行开始生效，而不是从参数在命令行或其他地方的使用中生效。例如，考虑这个 Dockerfile：
```dockerfile
FROM busybox
USER ${user:-some_user}
ARG user
USER $user
# ...
```
用户通过调用构建此文件：
```sh
docker build --build-arg user=what_user .
```
第 2 行的 USER 计算为 some_user，因为在随后的第 3 行定义了用户变量。第 4 行的 USER 计算为 what_user，因为定义了用户并且 what_user 值在命令行上传递。在由 ARG 指令定义之前，对变量的任何使用都会导致空字符串。 ARG 指令在定义它的构建阶段结束时超出范围。要在多个阶段使用 arg，每个阶段都必须包含 ARG 指令。

```dockerfile
FROM busybox
ARG SETTINGS
RUN ./run/setup $SETTINGS

FROM busybox
ARG SETTINGS
RUN ./run/other $SETTINGS
```
**使用ARG变量**
您可以使用 ARG 或 ENV 指令来指定可用于 RUN 指令的变量。使用 ENV 指令定义的环境变量总是覆盖同名的 ARG 指令。考虑这个带有 ENV 和 ARG 指令的 Dockerfile。
```dockerfile
FROM ubuntu
ARG CONT_IMG_VER
ENV CONT_IMG_VER=v1.0.0
RUN echo $CONT_IMG_VER
```
使用上面的示例但使用不同的 ENV 规范，您可以在 ARG 和 ENV 指令之间创建更有用的交互：
```dockerfile
FROM ubuntu
ARG CONT_IMG_VER
ENV CONT_IMG_VER=${CONT_IMG_VER:-v1.0.0}
RUN echo $CONT_IMG_VER
```
**预定义的 ARG**

Docker 有一组预定义的 ARG 变量，您无需在 Dockerfile 中使用相应的 ARG 指令即可使用这些变量。

- HTTP_PROXY
- http_proxy
- HTTPS_PROXY
- https_proxy
- FTP_PROXY
- ftp_proxy
- NO_PROXY
- no_proxy

要使用这些，请使用 --build-arg 标志在命令行上传递它们，例如：

```sh
docker build --build-arg HTTPS_PROXY=https://my-proxy.example.com .
```
**全局范围内的自动平台 ARG**
此功能仅在使用 BuildKit 后端时可用。 

Docker 预定义了一组 ARG 变量，其中包含有关执行构建的节点的平台（构建平台）和生成的映像的平台（目标平台）的信息。可以在 docker build 上使用 --platform 标志指定目标平台。 

以下 ARG 变量是自动设置的： 
  - TARGETPLATFORM - 构建结果的平台。例如 linux/amd64、linux/arm/v7、windows/amd64。 
  - TARGETOS - TARGETPLATFORM 的操作系统组件 
  - TARGETARCH - TARGETPLATFORM 的架构组件 
  - TARGETVARIANT - TARGETPLATFORM 的变体组件 
  - BUILDPLATFORM - 执行构建的节点的平台。 
  - BUILDOS - BUILDPLATFORM 的操作系统组件 
  - BUILDARCH - BUILDPLATFORM 的架构组件 
  - BUILDVARIANT - BUILDPLATFORM 的变体组件 
  
这些参数在全局范围内定义，因此不会在构建阶段或您的 RUN 命令中自动可用。在构建阶段公开这些参数之一，重新定义它没有价值。 
例如：
```dockerfile
FROM alpine
ARG TARGETPLATFORM
RUN echo "I'm building for $TARGETPLATFORM"
```
**对构建缓存的影响**
ARG 变量不会像 ENV 变量那样持久化到构建的映像中。但是，ARG 变量确实以类似的方式影响构建缓存。如果 Dockerfile 定义了一个 ARG 变量，其值与之前的构建不同，那么“缓存未命中”发生在它第一次使用时，而不是它的定义。特别是，ARG 指令之后的所有 RUN 指令都隐式使用 ARG 变量（作为环境变量），因此可能导致缓存未命中。除非 Dockerfile 中有匹配的 ARG 语句，否则所有预定义的 ARG 变量都免于缓存。 
例如，考虑这两个 Dockerfile：
```dockerfile
FROM ubuntu
ARG CONT_IMG_VER
RUN echo $CONT_IMG_VER
```
```dockerfile
FROM ubuntu
ARG CONT_IMG_VER
RUN echo hello
```
如果在命令行中指定 --build-arg CONT_IMG_VER=<value> ，在这两种情况下，第 2 行的指定都不会导致缓存未命中；第 3 行确实导致缓存未命中。 ARG CONT_IMG_VER 导致 RUN 行被标识为与运行 CONT_IMG_VER=<value> echo hello 相同，因此如果 <value> 更改，我们会得到缓存未命中。


### ONBUILD
```dockerfile
ONBUILD <INSTRUCTION>
```
ONBUILD 指令将一个触发指令添加到映像中，以便稍后在映像用作另一个构建的基础时执行。触发器将在下游构建的上下文中执行，就好像它是在下游 Dockerfile 中的 FROM 指令之后立即插入的一样。 
任何构建指令都可以注册为触发器。 

如果您正在构建将用作构建其他镜像的基础的镜像，例如应用程序构建环境或可以使用用户特定配置自定义的守护程序，这将非常有用。 

例如，如果您的映像是可重用的 Python 应用程序构建器，则需要将应用程序源代码添加到特定目录中，并且可能需要在此之后调用构建脚本。你现在不能只调用 ADD 和 RUN，因为你还没有访问应用程序源代码的权限，而且每个应用程序构建都会有所不同。您可以简单地为应用程序开发人员提供一个样板 Dockerfile 以将其复制粘贴到他们的应用程序中，但这效率低下、容易出错且难以更新，因为它与特定于应用程序的代码混合在一起。 

解决方案是使用 ONBUILD 注册高级指令，以便在下一个构建阶段运行。 

这是它的工作原理： 
  - 当遇到 ONBUILD 指令时，构建器会向正在构建的映像的元数据添加触发器。该指令不会以其他方式影响当前构建。 
  - 在构建结束时，所有触发器的列表存储在图像清单中的 OnBuild 键下。可以使用 docker inspect 命令检查它们。 
  - 稍后，可以使用 FROM 指令将该映像用作新构建的基础。作为处理 FROM 指令的一部分，下游构建器查找 ONBUILD 触发器，并按照它们注册的顺序执行它们。如果任何触发器失败，则 FROM 指令将中止，从而导致构建失败。如果所有触发器都成功，则 FROM 指令完成并且构建照常继续。 
  - 触发器在执行后从最终图像中清除。换句话说，它们不是由“孙子”构建继承的。 
  
例如，您可以添加如下内容：

```dockerfile
ONBUILD ADD . /app/src
ONBUILD RUN /usr/local/bin/python-build --dir /app/src
```
> 不允许使用 ONBUILD ONBUILD 链接 ONBUILD 指令。

> ONBUILD 指令可能不会触发 FROM 或 MAINTAINER 指令。

### STOPSIGNAL
```dockerfile
STOPSIGNAL signal
```
STOPSIGNAL 指令设置将发送到容器退出的系统调用信号。该信号可以是与内核系统调用表中的位置匹配的有效无符号数，例如 9，或格式为 SIGNAME 的信号名称，例如 SIGKILL。


### SHELL
```dockerfile
SHELL ["executable", "parameters"]
```
SHELL 指令允许覆盖用于命令的 shell 形式的默认 shell。 Linux 上的默认 shell 是 ["/bin/sh", "-c"]，Windows 上的默认 shell 是 ["cmd", "/S", "/C"]。 

SHELL 指令必须以 JSON 格式写入 Dockerfile。 SHELL 指令在 Windows 上特别有用，Windows 有两种常用且截然不同的本机 shell：cmd 和 powershell，以及可用的备用 shell，包括 sh。 

SHELL 指令可以出现多次。每条 SHELL 指令都会覆盖所有先前的 SHELL 指令，并影响所有后续指令。例如：

```dockerfile
FROM microsoft/windowsservercore

# Executed as cmd /S /C echo default
RUN echo default

# Executed as cmd /S /C powershell -command Write-Host default
RUN powershell -command Write-Host default

# Executed as powershell -command Write-Host hello
SHELL ["powershell", "-command"]
RUN Write-Host hello

# Executed as cmd /S /C echo hello
SHELL ["cmd", "/S", "/C"]
RUN echo hello
```
当在 Dockerfile 中使用它们的 shell 形式时，以下指令可能会受到 SHELL 指令的影响：RUN、CMD 和 ENTRYPOINT。 

下面的例子是在 Windows 上发现的一种常见模式，可以使用 SHELL 指令进行简化：
```dockerfile
RUN powershell -command Execute-MyCmdlet -param1 "c:\foo.txt"
```
docker 调用的命令将是：
```sh
cmd /S /C powershell -command Execute-MyCmdlet -param1 "c:\foo.txt"
```
这是低效的，原因有二。首先，调用了一个不必要的 cmd.exe 命令处理器（又名 shell）。其次，shell 形式中的每个 RUN 指令都需要一个额外的 powershell -command 前缀。 

为了使这更有效，可以采用两种机制之一。一种是使用 RUN 命令的 JSON 形式，例如：
```dockerfile
# escape=`

FROM microsoft/nanoserver
SHELL ["powershell","-command"]
RUN New-Item -ItemType Directory C:\Example
ADD Execute-MyCmdlet.ps1 c:\example\
RUN c:\example\Execute-MyCmdlet -sample 'hello world'
```
