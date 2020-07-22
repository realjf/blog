---
title: "php扩展开发 php Extension Develop"
date: 2020-05-18T16:00:22+08:00
keywords: ["php"]
categories: ["php"]
tags: ["php"]
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

### 下载php源代码
要开发php扩展，需要下载php源码，里面有我们开发扩展需要的工具

下载地址：[https://www.php.net/downloads](https://www.php.net/downloads)

```bash
wget https://www.php.net/distributions/php-7.4.6.tar.xz
xz -d php-7.4.6.tar.xz
tar xvf php-7.4.6.tar

```

我们需要的是源码目录下ext目录下的ext_skel或ext_skel.php文件，它是类unix环境下用于自动生成php扩展框架的脚本工具。


### 开发自己的php扩展
可以通过--help查看ext_skel.php的完整命令
```bash
ext_skel --help
```
首先，我们需要利用ext_skel.php生成我们需要的框架，只需要提供--extname的参数即可
```bash
# 5.6.23
./ext_skel --extname=helloworld

# 7.4.6
./ext_skel.php --ext helloworld

```

运行之后，在ext目录下将多出一个helloworld的目录，即我们生成的扩展框架目录

目录下包含以下文件：
- config.m4：这是Unix环境下的Build System配置文件，后面将会通过它生成配置和安装。
- php_helloworld.h：这个文件是扩展模块的头文件。遵循C语言一贯的作风，这个里面可以放置一些自定义的结构体、全局变量等等。
- helloworld.c：这个就是扩展模块的主程序文件了，最终的扩展模块各个函数入口都在这里。当然，你可以将所有程序代码都塞到这里面，也可以遵循模块化思想，将各个功能模块放到不同文件中


#### build system配置
这里看下config.m4配置的一些内容，打开config.m4，注意，其使用dnl作为注释符
```bash
dnl config.m4 for extension helloworld

dnl Comments in this file start with the string 'dnl'.
dnl Remove where necessary.

dnl If your extension references something external, use 'with':

dnl PHP_ARG_WITH([helloworld],
dnl   [for helloworld support],
dnl   [AS_HELP_STRING([--with-helloworld],
dnl     [Include helloworld support])])

dnl Otherwise use 'enable':

PHP_ARG_ENABLE([helloworld],
  [whether to enable helloworld support],
  [AS_HELP_STRING([--enable-helloworld],
    [Enable helloworld support])],
  [no])

if test "$PHP_HELLOWORLD" != "no"; then
  dnl Write more examples of tests here...

  dnl Remove this code block if the library does not support pkg-config.
  dnl PKG_CHECK_MODULES([LIBFOO], [foo])
  dnl PHP_EVAL_INCLINE($LIBFOO_CFLAGS)
  dnl PHP_EVAL_LIBLINE($LIBFOO_LIBS, HELLOWORLD_SHARED_LIBADD)

  dnl If you need to check for a particular library version using PKG_CHECK_MODULES,
  dnl you can use comparison operators. For example:
  dnl PKG_CHECK_MODULES([LIBFOO], [foo >= 1.2.3])
  dnl PKG_CHECK_MODULES([LIBFOO], [foo < 3.4])
  dnl PKG_CHECK_MODULES([LIBFOO], [foo = 1.2.3])

  dnl Remove this code block if the library supports pkg-config.
  dnl --with-helloworld -> check with-path
  dnl SEARCH_PATH="/usr/local /usr"     # you might want to change this
  dnl SEARCH_FOR="/include/helloworld.h"  # you most likely want to change this
  dnl if test -r $PHP_HELLOWORLD/$SEARCH_FOR; then # path given as parameter
  dnl   HELLOWORLD_DIR=$PHP_HELLOWORLD
  dnl else # search default path list
  dnl   AC_MSG_CHECKING([for helloworld files in default path])
  dnl   for i in $SEARCH_PATH ; do
  dnl     if test -r $i/$SEARCH_FOR; then
  dnl       HELLOWORLD_DIR=$i
  dnl       AC_MSG_RESULT(found in $i)
  dnl     fi
  dnl   done
  dnl fi
  dnl
  dnl if test -z "$HELLOWORLD_DIR"; then
  dnl   AC_MSG_RESULT([not found])
  dnl   AC_MSG_ERROR([Please reinstall the helloworld distribution])
  dnl fi

  dnl Remove this code block if the library supports pkg-config.
  dnl --with-helloworld -> add include path
  dnl PHP_ADD_INCLUDE($HELLOWORLD_DIR/include)

  dnl Remove this code block if the library supports pkg-config.
  dnl --with-helloworld -> check for lib and symbol presence
  dnl LIBNAME=HELLOWORLD # you may want to change this
  dnl LIBSYMBOL=HELLOWORLD # you most likely want to change this

  dnl If you need to check for a particular library function (e.g. a conditional
  dnl or version-dependent feature) and you are using pkg-config:
  dnl PHP_CHECK_LIBRARY($LIBNAME, $LIBSYMBOL,
  dnl [
  dnl   AC_DEFINE(HAVE_HELLOWORLD_FEATURE, 1, [ ])
  dnl ],[
  dnl   AC_MSG_ERROR([FEATURE not supported by your helloworld library.])
  dnl ], [
  dnl   $LIBFOO_LIBS
  dnl ])

  dnl If you need to check for a particular library function (e.g. a conditional
  dnl or version-dependent feature) and you are not using pkg-config:
  dnl PHP_CHECK_LIBRARY($LIBNAME, $LIBSYMBOL,
  dnl [
  dnl   PHP_ADD_LIBRARY_WITH_PATH($LIBNAME, $HELLOWORLD_DIR/$PHP_LIBDIR, HELLOWORLD_SHARED_LIBADD)
  dnl   AC_DEFINE(HAVE_HELLOWORLD_FEATURE, 1, [ ])
  dnl ],[
  dnl   AC_MSG_ERROR([FEATURE not supported by your helloworld library.])
  dnl ],[
  dnl   -L$HELLOWORLD_DIR/$PHP_LIBDIR -lm
  dnl ])
  dnl
  dnl PHP_SUBST(HELLOWORLD_SHARED_LIBADD)

  dnl In case of no dependencies
  AC_DEFINE(HAVE_HELLOWORLD, 1, [ Have helloworld support ])

  PHP_NEW_EXTENSION(helloworld, helloworld.c, $ext_shared)
fi
```
大致上如果要引用外部模块等，需要在这里配置

#### 编写扩展代码
编写PHP扩展是基于Zend API和一些宏，首先需要搞清楚php extension的结构。
其实质上就是zend_module_entry结构体，可以查阅zend/zend_modules.h文件
```c
   68 typedef struct _zend_module_entry zend_module_entry;
   69 typedef struct _zend_module_dep zend_module_dep;
   70 
   71 struct _zend_module_entry {
   72     unsigned short size;
   73     unsigned int zend_api;
   74     unsigned char zend_debug;
   75     unsigned char zts;
   76     const struct _zend_ini_entry *ini_entry;
   77     const struct _zend_module_dep *deps;
   78     const char *name;
   79     const struct _zend_function_entry *functions;
   80     int (*module_startup_func)(INIT_FUNC_ARGS);
   81     int (*module_shutdown_func)(SHUTDOWN_FUNC_ARGS);
   82     int (*request_startup_func)(INIT_FUNC_ARGS);
   83     int (*request_shutdown_func)(SHUTDOWN_FUNC_ARGS);
   84     void (*info_func)(ZEND_MODULE_INFO_FUNC_ARGS);
   85     const char *version;
   86     size_t globals_size;
   87 #ifdef ZTS
   88     ts_rsrc_id* globals_id_ptr;
   89 #else
   90     void* globals_ptr;
   91 #endif
   92     void (*globals_ctor)(void *global);
   93     void (*globals_dtor)(void *global);
   94     int (*post_deactivate_func)(void);
   95     int module_started;
   96     unsigned char type;
   97     void *handle;
   98     int module_number;
   99     const char *build_id;                                                                                                                                                          
  100 };

```
解释下：

- name：扩展的名字
- functions：存放此扩展中定义的函数的引用

第9-12个字段分别是四个函数指针，这四个函数会在相应时机被调用，
分别是“扩展模块加载时”、“扩展模块卸载时”、“每个请求开始时”和“每个请求结束时”。
这四个函数可以看成是一种拦截机制，主要用于相应时机的资源分配、释放等相关操作。

- info_func： 是一个函数指针，这个指针指向的函数会在执行phpinfo()时被调用，用于显示自定义模块信息。
- version：模块的版本


介绍完以上字段，我们可以看看“helloworld.c”中自动生成的“helloworld_module_entry”框架代码了

```c
/* helloworld extension for PHP */

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "php.h"
#include "ext/standard/info.h"
#include "php_helloworld.h"

/* For compatibility with older PHP versions */
#ifndef ZEND_PARSE_PARAMETERS_NONE
#define ZEND_PARSE_PARAMETERS_NONE() \
	ZEND_PARSE_PARAMETERS_START(0, 0) \
	ZEND_PARSE_PARAMETERS_END()
#endif

/* {{{ void helloworld_test1()
 */
PHP_FUNCTION(helloworld_test1)
{
	ZEND_PARSE_PARAMETERS_NONE();

	php_printf("The extension %s is loaded and working!\r\n", "helloworld");
}
/* }}} */

/* {{{ string helloworld_test2( [ string $var ] )
 */
PHP_FUNCTION(helloworld_test2)
{
	char *var = "World";
	size_t var_len = sizeof("World") - 1;
	zend_string *retval;

	ZEND_PARSE_PARAMETERS_START(0, 1)
		Z_PARAM_OPTIONAL
		Z_PARAM_STRING(var, var_len)
	ZEND_PARSE_PARAMETERS_END();

	retval = strpprintf(0, "Hello %s", var);

	RETURN_STR(retval);
}
/* }}}*/

/* {{{ PHP_RINIT_FUNCTION
 */
PHP_RINIT_FUNCTION(helloworld)
{
#if defined(ZTS) && defined(COMPILE_DL_HELLOWORLD)
	ZEND_TSRMLS_CACHE_UPDATE();
#endif

	return SUCCESS;
}
/* }}} */

/* {{{ PHP_MINFO_FUNCTION
 */
PHP_MINFO_FUNCTION(helloworld)
{
	php_info_print_table_start();
	php_info_print_table_header(2, "helloworld support", "enabled");
	php_info_print_table_end();
}
/* }}} */

/* {{{ arginfo
 */
ZEND_BEGIN_ARG_INFO(arginfo_helloworld_test1, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO(arginfo_helloworld_test2, 0)
	ZEND_ARG_INFO(0, str)
ZEND_END_ARG_INFO()
/* }}} */

/* {{{ helloworld_functions[]
 */
static const zend_function_entry helloworld_functions[] = {
	PHP_FE(helloworld_test1,		arginfo_helloworld_test1)
	PHP_FE(helloworld_test2,		arginfo_helloworld_test2)
	PHP_FE_END
};
/* }}} */

/* {{{ helloworld_module_entry
 */
zend_module_entry helloworld_module_entry = {
	STANDARD_MODULE_HEADER,
	"helloworld",					/* Extension name */
	helloworld_functions,			/* zend_function_entry */
	NULL,							/* PHP_MINIT - Module initialization */
	NULL,							/* PHP_MSHUTDOWN - Module shutdown */
	PHP_RINIT(helloworld),			/* PHP_RINIT - Request initialization */
	NULL,							/* PHP_RSHUTDOWN - Request shutdown */
	PHP_MINFO(helloworld),			/* PHP_MINFO - Module info */
	PHP_HELLOWORLD_VERSION,		/* Version */
	STANDARD_MODULE_PROPERTIES
};
/* }}} */

#ifdef COMPILE_DL_HELLOWORLD
# ifdef ZTS
ZEND_TSRMLS_CACHE_DEFINE()
# endif
ZEND_GET_MODULE(helloworld)
#endif
```
- PHP_MINIT_FUNCTION => 模块初始化阶段（M就是module的含义，init就是initial）
- PHP_MSHUTDOWN_FUNCTION => 模块关闭阶段（M就是module的含义，后面就是shutdown）
- PHP_RINIT_FUNCTION => 请求初始化（R就是request的含义，init就是initial）
- PHP_RSHUTDOWN_FUNCTION => 请求关闭阶段（R就是request的含义，后面就是shutdown）
- PHP_MINFO_FUNCTION 指获取模块信息

宏“STANDARD_MODULE_HEADER”会生成前6个字段，“STANDARD_MODULE_PROPERTIES ”会生成“version”后的字段
这里要注意，几个宏的参数均为“helloworld”，但这并不表示几个函数的名字全为“helloworld”，
C语言中也不可能存在函数名重载机制。实际上，在开发PHP Extension的过程中，几乎处处都要用到Zend里预定义的各种宏，
从全局变量到函数的定义甚至返回值，都不能按照“裸写”的方式来编写C语言，这是因为PHP的运行机制可能会导致命名冲突等问题，
而这些宏会将函数等元素变换成一个内部名称，但这些对程序员都是透明的。


我们的任务就是：

- 第一，如果需要在相应时机处理一些东西，那么需要填充各个拦截函数内容；
- 第二，编写say_hello的功能函数，并将引用添加到say_hello_functions中。

#### 编写phpinfo()回调函数

因为hellowolrd扩展在各个生命周期阶段并不需要做操作，所以我们只编写info_func的内容，上文说过，这个函数将在phpinfo()执行时被自动调用，用于显示扩展的信息。编写这个函数会用到四个函数：

- php_info_print_table_start()——开始phpinfo表格。无参数。
- php_info_print_table_header()——输出表格头。第一个参数是整形，指明头的列数，然后后面的参数是与列数等量的(char*)类型参数用于指定显示的文字。
- php_info_print_table_row()——输出表格内容。第一个参数是整形，指明这一行的列数，然后后面的参数是与列数等量的(char*)类型参数用于指定显示的文字。
- php_info_print_table_end()——结束phpinfo表格。无参数

下面编写具体的代码：

```c
/* {{{ PHP_MINFO_FUNCTION
 */
PHP_MINFO_FUNCTION(helloworld)
{
	php_info_print_table_start();
	php_info_print_table_header(2, "helloworld support", "enabled");
	php_info_print_table_row(2, "author, "realjf"); // 新增
	php_info_print_table_end();
}
/* }}} */
```

#### 编写核心函数
编写核心函数，总共分为三步：

- 1、使用宏PHP_FUNCTION定义函数体；
- 2、使用宏ZEND_BEGIN_ARG_INFO和ZEND_END_ARG_INFO定义参数信息；
- 3、使用宏PHP_FE将函数加入到say_hello_functions中。


##### 使用宏PHP_FUNCTION定义函数体
```c
PHP_FUNCTION(helloworld_func)
{
    char *name;
    int name_len;
    if (zend_parse_parameters(ZEND_NUM_ARGS() TSRMLS_CC, "s", &name, &name_len) == FAILURE)
    {
        return;
    }
    php_printf("Hello %s!", name);
    RETURN_TRUE;
}
```
我们一行行解释：

首先，由上述函数实现可以看出，函数的外部名称就是宏后面括号里面的名称，

声明局部变量大致与c语言类似

解析参数通过zend_parse_parameters函数实现，这个函数的作用是从函数用户的输入栈中读取数据，
然后转换成相应的函数参数填入变量以供后面核心功能代码使用。

zend_parse_parameters的

- 第一个参数是用户传入参数的个数，可以由宏“ZEND_NUM_ARGS() TSRMLS_CC”生成；
- 第二个参数是一个字符串，其中每个字母代表一个变量类型，我们只有一个字符串型变量，所以第二个参数是“s”；
- 最后各个参数需要一些必要的局部变量指针用于存储数据

下表给出了不同变量类型的字母代表及其所需要的局部变量指针
![/image/php_zend_parse_parameters.png](/image/php_zend_parse_parameters.png)


参数解析完成后就是核心功能代码，我们这里只是输出一行字符，php_printf是Zend版本的printf。

最后的返回值也是通过宏实现的。RETURN_TRUE宏是返回布尔值“true”

可以设置return_value，但php提供了设置返回值的宏
```c
#define RETURN_BOOL(b)                     { RETVAL_BOOL(b); return; }
#define RETURN_NULL()                     { RETVAL_NULL(); return;}
#define RETURN_LONG(l)                     { RETVAL_LONG(l); return; }
#define RETURN_DOUBLE(d)                 { RETVAL_DOUBLE(d); return; }
#define RETURN_STR(s)                     { RETVAL_STR(s); return; }
#define RETURN_INTERNED_STR(s)            { RETVAL_INTERNED_STR(s); return; }
#define RETURN_NEW_STR(s)                { RETVAL_NEW_STR(s); return; }
#define RETURN_STR_COPY(s)                { RETVAL_STR_COPY(s); return; }
#define RETURN_STRING(s)                 { RETVAL_STRING(s); return; }
#define RETURN_STRINGL(s, l)             { RETVAL_STRINGL(s, l); return; }
#define RETURN_EMPTY_STRING()             { RETVAL_EMPTY_STRING(); return; }
#define RETURN_RES(r)                     { RETVAL_RES(r); return; }
#define RETURN_ARR(r)                     { RETVAL_ARR(r); return; }
#define RETURN_OBJ(r)                     { RETVAL_OBJ(r); return; }
#define RETURN_ZVAL(zv, copy, dtor)        { RETVAL_ZVAL(zv, copy, dtor); return; }
#define RETURN_FALSE                      { RETVAL_FALSE; return; }
#define RETURN_TRUE                       { RETVAL_TRUE; return; }
#define RETURN_RESOURCE(r)	               { RETVAL_RESOURCE(r) } // 设置资源句柄
```



##### 使用宏ZEND_BEGIN_ARG_INFO和ZEND_END_ARG_INFO定义参数信息
代码如下：
```c
/* {{{ arginfo
 */
ZEND_BEGIN_ARG_INFO(arginfo_helloworld_test1, 0)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO(arginfo_helloworld_test2, 0)
	ZEND_ARG_INFO(0, str)
ZEND_END_ARG_INFO()

ZEND_BEGIN_ARG_INFO(arginfo_helloworld_func, 0)
ZEND_END_ARG_INFO() // 新增
/* }}} */


```

使用宏PHP_FE将函数加入到helloworld_functions中

最后，我们需要将刚才定义的函数和参数信息加入到helloworld_functions数组里，代码如下

```c
/* {{{ helloworld_functions[]
 */
static const zend_function_entry helloworld_functions[] = {
	PHP_FE(helloworld_test1,		arginfo_helloworld_test1)
	PHP_FE(helloworld_test2,		arginfo_helloworld_test2)
	PHP_FE(helloworld_func,         arginfo_helloworld_func)
	PHP_FE_END
};
/* }}} */
```
这一步就是通过PHP_EF宏实现，注意这个数组最后一行必须是PHP_FE_END，请不要删除


至此，我们的扩展已完成编写

#### 编译并安装扩展
在helloworld目录下运行如下命令：
```bash
/usr/bin/phpize
./configure
make
make install

```

这样就会发现在ls -al /usr/lib/php/20180731/ 中多了一个helloworld.so文件

在php.ini文件中加入该扩展
```bash
extension=helloworld.so
```
使用phpinfo()函数查看扩展信息


使用脚本测试
```bash
php -r 'helloworld_func("realjf");'
```



