---
title: "nasm汇编之变量 Variables"
date: 2020-05-31T01:50:22+08:00
keywords: ["assembly"]
categories: ["assembly"]
tags: ["assembly"]
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

NASM提供了各种定义指令来为变量保留存储空间。 define assembler指令用于分配存储空间。它可以用于保留以及初始化一个或多个字节


### 为初始化数据分配存储空间
初始化数据的存储分配语句的语法为
```asm
[variable-name]    define-directive    initial-value   [,initial-value]...
```
其中，变量名是每个存储空间的标识符。汇编器为数据段中定义的每个变量名称关联一个偏移值。

五种基本类型指令

| 指令 | 说明 | 存储空间 |
|:---:|:---:|:---:|
|DB | 定义字节| 1 byte|
|DW | 定义字| 2 bytes|
|DD | 定义双字| 4 bytes|
|DQ | 定义四字| 8 bytes|
|DT | 定义10字| 10 bytes|

示例
```asm
choice		DB	'y'
number		DW	12345
neg_number	DW	-12345
big_number	DQ	123456789
real_number1	DD	1.234
real_number2	DQ	123.456
```

注意：
- 字符的每个字节均以十六进制形式存储为其ASCII值
- 每个十进制值都将自动转换为其等效的16位二进制数，并存储为十六进制数
- 处理器使用小尾数字节排序
- 负数将转换为2的补码表示形式
- 短浮点数和长浮点数分别使用32位或64位表示。

```asm
Live Demo
section .text
   global _start          ;must be declared for linker (gcc)
	
_start:                   ;tell linker entry point
   mov	edx,1		  ;message length
   mov	ecx,choice        ;message to write
   mov	ebx,1		  ;file descriptor (stdout)
   mov	eax,4		  ;system call number (sys_write)
   int	0x80		  ;call kernel

   mov	eax,1		  ;system call number (sys_exit)
   int	0x80		  ;call kernel

section .data
choice DB 'y'
```

### 分配未初始化数据的存储空间
reserve指令用于为未初始化的数据保留空间。 reserve指令采用单个操作数，该操作数指定要保留的空间单位数。每个define指令都有一个相关的reserve指令

五种基本reserve指令

| 指令 | 说明 |
|:---:|:---:|
| RESB | 1 byte |
| RESW | 2 bytes |
| RESD | 4 bytes |
| RESQ | 8 bytes |
| REST | 10 bytes |


### 多重初始化
> 汇编器为多个变量定义分配连续的内存

TIMES指令允许多次初始化为相同的值。

例如，可以使用以下语句定义一个大小为9的标记的数组并将其初始化为零
```asm
marks  TIMES  9  DW  0
```
TIMES指令在定义数组和表时很有用。下面的程序在屏幕上显示9个星号
```asm
Live Demo
section	.text
   global _start        ;must be declared for linker (ld)
	
_start:                 ;tell linker entry point
   mov	edx,9		;message length
   mov	ecx, stars	;message to write
   mov	ebx,1		;file descriptor (stdout)
   mov	eax,4		;system call number (sys_write)
   int	0x80		;call kernel

   mov	eax,1		;system call number (sys_exit)
   int	0x80		;call kernel

section	.data
stars   times 9 db '*'
```





