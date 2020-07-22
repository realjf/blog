---
title: "nasm汇编之数组 Arrays"
date: 2020-05-31T03:23:36+08:00
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

汇编程序的数据定义指令用于为变量分配存储空间。
变量也可以用一些特定的值初始化。初始化值可以以十六进制，十进制或二进制形式指定

我们可以通过以下两种方式之一来定义单词变量“ months”
```asm
MONTHS	DW	12
MONTHS	DW	0CH
MONTHS	DW	0110B
```
数据定义指令还可用于定义一维数组。让我们定义一维数字数组
```asm
NUMBERS	DW  34,  45,  56,  67,  75, 89
```
上面的定义声明了一个六个字的数组，每个字都用数字34、45、56、67、75、89初始化。这分配了2x6 = 12个字节的连续存储空间。
第一个数字的符号地址为NUMBERS，第二个数字的符号地址为NUMBERS + 2，依此类推

您可以定义一个大小为8的名为清单的数组，并将所有值初始化为零，如下所示：
```asm
INVENTORY   DW  0
            DW  0
            DW  0
            DW  0
            DW  0
            DW  0
            DW  0
            DW  0
```
可以缩写为
```asm
INVENTORY   DW  0, 0 , 0 , 0 , 0 , 0 , 0 , 0
```
TIMES指令还可用于将多个初始化为相同的值。使用TIMES，可以将INVENTORY数组定义为
```asm
INVENTORY TIMES 8 DW 0
```

示例
```asm
section	.text
   global _start   ;must be declared for linker (ld)
	
_start:	
 		
   mov  eax,3      ;number bytes to be summed 
   mov  ebx,0      ;EBX will store the sum
   mov  ecx, x     ;ECX will point to the current element to be summed

top:  add  ebx, [ecx]

   add  ecx,1      ;move pointer to next element
   dec  eax        ;decrement counter
   jnz  top        ;if counter not 0, then loop again

done: 

   add   ebx, '0'
   mov  [sum], ebx ;done, store result in "sum"

display:

   mov  edx,1      ;message length
   mov  ecx, sum   ;message to write
   mov  ebx, 1     ;file descriptor (stdout)
   mov  eax, 4     ;system call number (sys_write)
   int  0x80       ;call kernel
	
   mov  eax, 1     ;system call number (sys_exit)
   int  0x80       ;call kernel

section	.data
global x
x:    
   db  2
   db  4
   db  3

sum: 
   db  0
```





