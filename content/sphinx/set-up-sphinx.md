---
title: "安装 Sphinx"
date: 2020-04-28T14:26:34+08:00
keywords: [""]
categories: ["sphinx"]
tags: [""]
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

#### 简介
sphinx是由俄罗斯人开发的一个全文检索引擎。旨在为其他应用提供高速、低空间占用、告诫过相关度的全文搜索功能。

特性:
- 高速的建立索引（在现代cpu上，峰值性能可达到10MB/秒）;
- 高性能的搜索（在2~4GB的文本数据上，平均每次检索响应时间小于0.1秒）
- 可处理海量数据（目前已知可以处理超过100GB的文本数据，在单一CPU系统上可处理100M文档）
- 提供了优秀的相关度算法，基于短语相似度和统计的复合Ranking方法。
- 支持分布式搜索
- 支持短语搜索
- 提供文档摘要生成
- 可作为mysql的存储引擎提供搜索服务
- 支持布尔、短语、词语相似度等多种检索模式
- 文档支持多个全文检索字段（最大不超过32个）
- 文档支持多个额外的属性信息
- 支持断词




官网地址：[http://sphinxsearch.com/](http://sphinxsearch.com/)

下载地址：[http://sphinxsearch.com/downloads/current/](http://sphinxsearch.com/downloads/current/)


二进制地址：[http://sphinxsearch.com/files/sphinx-3.0.2-2592786-linux-amd64.tar.gz](http://sphinxsearch.com/files/sphinx-3.0.2-2592786-linux-amd64.tar.gz)

源码包地址：[http://sphinxsearch.com/files/sphinx-2.2.11-release.tar.gz](http://sphinxsearch.com/files/sphinx-2.2.11-release.tar.gz)


中文文档地址：[http://www.sphinxsearch.org/archives/category/php](http://www.sphinxsearch.org/archives/category/php)

#### sphinx在mysql上的应用有两种方式：
1. 采用api调用，如php、java等的api函数或方法查询。优点是可不必对mysql重新编译，服务端进程“低耦合”，且程序灵活度高、方便调用。
2. 使用插件方式 sphinxSE把sphinx编译成一个mysql插件并使用特定的sql语句进行检索。
3. 通过安装相关编程语言的扩展插件


#### 准备
- mysql
- mysql-devel
- 编译软件gcc gcc-c++ autoconf automake
- sphinx
```
# 安装工具
yum install -y make gcc libtool gcc-c++ g++ autoconf imake automake mysql-devel libxml2-devel expat-devel

```
#### sphinx安装
```
# 下载
wget http://sphinxsearch.com/files/sphinx-2.2.11-release.tar.gz

# 解压
tar zxvf sphinx-2.2.11-release.tar.gz

# 安装
./configure --prefix=/usr/local/sphinx
make && make install

# 备份配置文件
cd /usr/local/sphinx/etc
cp sphinx.conf.dist sphinx.conf

```

#### coreseek下载地址
coreseek下载地址：[http://blog.realjf.com/wp-content/uploads/2018/03/coreseek-3.2.14.tar.gz](http://blog.realjf.com/wp-content/uploads/2018/03/coreseek-3.2.14.tar.gz)

百度分享地址：[https://pan.baidu.com/s/1wwk5gEx4atyBHxCiwXsZtw](https://pan.baidu.com/s/1wwk5gEx4atyBHxCiwXsZtw)

```
# 准备
locale
LANG=zh_CN.UTF-8
LC_ALL="zh_CN.UTF-8"

# 以下核心项，locale为zh_CN.UTF-8，就可以正常显示和输入中文，locale设置功能由操作系统自身支持，BSD/Linux均可开启；该功能，不是coreseek提供的。
# 如果需要修改，可以使用export LANG=zh_CN.UTF-8进行修改
```
#### 安装coreseek开发的mmseg，为coreseek提供中文分词功能
```
tar zxvf coreseek-3.2.14.tar.gz
cd mmseg-3.2.14
./bootstrap
./configure --prefix=/usr/local/mmseg3
make && make install


# 安装完成后，mmseg使用的词典和配置文件，将自动安装到/usr/local/mmseg3/etc中
# 中文分词测试
/usr/local/mmseg3/bin/mmseg -d /usr/local/mmseg3/etc src/t1.txt
# 输出结果如下:
中文/x 分/x 词/x 测试/x 
中国人/x 上海市/x 

Word Splite took: 0 ms.

```

#### 安装coreseek
```
cd ..
cd csft-3.2.14
# 执行并配置
sh buildconf.sh
./configure --prefix=/usr/local/coreseek  --without-unixodbc --with-mmseg --with-mmseg-includes=/usr/local/mmseg3/include/mmseg/ --with-mmseg-libs=/usr/local/mmseg3/lib/ --with-mysql=/usr/local/mysql

# 如果出现找不到mysql includes file则使用以下编译命令

./configure --prefix=/usr/local/coreseek --without-unixodbc --with-mmseg --with-mmseg-includes=/usr/local/mmseg3/include/mmseg/ --with-mmseg-libs=/usr/local/mmseg3/lib/ --with-mysql-includes=/alidata/server/mysql/include/ --with-mysql-libs=/alidata/server/mysql/bin/ 

make && make install
```
如果编译报错，由于是gcc版本问题，所以需要手动修改以下内容

vim  /usr/local/src/coreseek-4.1-beta/csft-4.1/src/sphinxexpr.cpp
```
error: ‘ExprEval’ was not declared in this scope, and no declarations were found by argument-dependent lookup at the point of instantiation [-fpermissive]
   T val = ExprEval ( this->m_pArg, tMatch ); // 'this' fixes gcc braindamage
   
# 解决办法：
1013 T val = ExprEval ( this->m_pArg, tMatch ); // 'this' fixes gcc braindamage
# 修改为
T val = this->ExprEval ( this->m_pArg, tMatch ); // 'this' fixes gcc braindamage

1047 T val = ExprEval ( this->m_pArg, tMatch );
# 修改为
T val = this->ExprEval ( this->m_pArg, tMatch );
1080 T val = ExprEval ( this->m_pArg, tMatch );
# 修改为
T val = this->ExprEval ( this->m_pArg, tMatch );

```

如果缺少python环境的devel支持包，则
```
yum install -y python-devel
```


#### 测试mmseg分词和coreseek检索
```shell
cd coreseek-3.2.14/testpack
cat var/test/test.xml
# 测试mmseg分词
/usr/local/mmseg3/bin/mmseg -d /usr/local/mmseg3/etc var/test/test.xml

# 建立索引
/usr/local/coreseek/bin/indexer -c /usr/local/coreseek/etc/example.conf --all
# 如果运行报错
# /usr/local/coreseek/bin/indexer: error while loading shared libraries: libmysqlclient.so.20: cannot open shared object file: No such file or directory
# 解决办法是
locate libmysqlclient.so.20

/usr/local/mysql/lib/libmysqlclient.so.20
/usr/local/mysql/lib/libmysqlclient.so.20.3.4
/usr/local/src/mysql-5.7.17/libmysql/libmysqlclient.so.20
/usr/local/src/mysql-5.7.17/libmysql/libmysqlclient.so.20.3.4

# 以上输出内容可以看出，/usr/local/mysql/lib/libmysqlclient.so.20

vim /etc/ld.so.conf
# 新增一行 /usr/local/mysql/lib/
# 然后执行ldconfig生效

/usr/local/coreseek/bin/search -c etc/csft.conf # 网络搜索

```

> 如果没有locate命令，则运行以下命令安装
```
yum install mlocate
updatedb
# 现在可以使用locate了
```

#### 一些常用命令
```
# 开启搜索服务
/usr/local/coreseek/bin/searchd -c etc/csft.conf
# 停止搜索服务
/usr/local/coreseek/bin/searchd -c etc/csft.conf --stop

# 如已启动服务，要更新索引
/usr/local/coreseek/bin/indexer -c /usr/local/coreseek/etc/example.conf --all --rotate


```


#### 配置
> mysql数据源的配置可参考testpack/etc/csft_mysql.conf文件

```
# 修改sphinx配置
vim /usr/local/sphinx/etc/sphinx.conf
# sql_host = localhost // 主机地址
# sql_user = root // 数据库账户
# sql_pass = qaz325234 // 数据库密码 数据库密码
```

### Q&A

安装遇到的错误和问题解决方案


1、测试mmseg分词的时候

执行

/usr/local/coreseek/bin/indexer -c etc/csft.conf --all

提示下面的错误：

/usr/local/coreseek/bin/indexer: error while loading shared libraries: libmysqlclient.so.18: cannot open shared object file: No such file or directory

原因：sphinx indexer的依赖库ibmysqlclient.so.18找不到。

解决办法：

vi /etc/ld.so.conf
加入 /usr/local/mysql/lib

然后运行 ldconfig

问题解决

2、执行索引的时候

/usr/local/coreseek/bin/indexer -c /usr/local/coreseek/etc/csft_ttd_search.conf --all --rotate

提示下面的错误：


FATAL: failed to open /usr/local/coreseek/var/data/ttd_article/.tmp.spl: No such file or directory, will not index. Try --rotate option.

原因：source源找不到mysql.sock

解决办法：在配置文件csft_ttd_search.conf（自己创建的文件）的 source源 加入下面的代码

sql_sock   = /tmp/mysql.sock

3、执行索引的时候，出现的警告，导致索引没创建成功


WARNING: failed to open pid_file '/usr/local/coreseek/var/log/searchd_ttd_search.pid'.
WARNING: indices NOT rotated.

原因：找不到searchd_ttd_search.pid文件

解决办法：在’/usr/local/coreseek/var/log 下创建searchd_ttd_search.pid文件

再执行/usr/local/coreseek/bin/indexer -c /usr/local/coreseek/etc/csft_ttd_search.conf –all –rotate
出现了另外一个警告：


WARNING: failed to scanf pid from pid_file '/usr/local/coreseek/var/log/searchd_ttd_search.pid'.
WARNING: indices NOT rotated.

原因：虽然创建了searchd_ttd_search.pid文件，但是里面没有写入进程id

解决办法（根本原因）：在执行索引之前没有启动searchd服务，因此执行下面的命令

/usr/local/coreseek/bin/searchd --config /usr/local/coreseek/etc/ttd_search.conf

出现了期待已久的成功提示：


Coreseek Fulltext 3.2 [ Sphinx 0.9.9-release (r2117)]
Copyright (c) 2007-2011,
Beijing Choice Software Technologies Inc (http://www.coreseek.com)

using config file '/usr/local/coreseek/etc/ttd_search.conf'...
listening on all interfaces, port=9312
rotating index 'mysql': success



