---
title: "nasm汇编之数值 Numbers"
date: 2020-05-31T03:23:19+08:00
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

数值数据通常用二进制表示。算术指令对二进制数据进行操作。当数字显示在屏幕上或通过键盘输入时，它们为ASCII格式

此类转换会产生开销，并且汇编语言编程允许以更有效的方式以二进制形式处理数字。小数可以两种形式表示

- ASCII格式
- BCD或者二进制编码的十进制形式

### ASCII表示
在ASCII表示中，十进制数字存储为ASCII字符串

有四条指令以ASCII表示形式处理数字

- AAA ASCII Adjust After Addition
- AAS ASCII Adjust After Subtraction
- AAM ASCII Adjust After Multiplication
- AAD ASCII Adjust Before Division

这些指令不使用任何操作数，并假定所需的操作数位于AL寄存器中


示例
```asm
section	.text
   global _start        ;must be declared for using gcc
	
_start:	                ;tell linker entry point
   sub     ah, ah
   mov     al, '9'
   sub     al, '3'
   aas
   or      al, 30h
   mov     [res], ax
	
   mov	edx,len	        ;message length
   mov	ecx,msg	        ;message to write
   mov	ebx,1	        ;file descriptor (stdout)
   mov	eax,4	        ;system call number (sys_write)
   int	0x80	        ;call kernel
	
   mov	edx,1	        ;message length
   mov	ecx,res	        ;message to write
   mov	ebx,1	        ;file descriptor (stdout)
   mov	eax,4	        ;system call number (sys_write)
   int	0x80	        ;call kernel
	
   mov	eax,1	        ;system call number (sys_exit)
   int	0x80	        ;call kernel
	
section	.data
msg db 'The Result is:',0xa	
len equ $ - msg			
section .bss
res resb 1 
```

### BCD表示
有两种BCD表示

- 开箱BCD
- 封箱BCD

在未压缩的BCD表示形式中，每个字节都存储一个十进制数字的二进制等效项.

有两条指令处理数字

- AAM ASCII Adjust After Multiplication
- AAD ASCII Adjust Before Division

四个ASCII调整指令AAA，AAS，AAM和AAD也可以与未打包的BCD表示一起使用。在打包的BCD表示中，每个数字使用四位存储。
两个十进制数字打包成一个字节。

有两个处理这些数字的说明

- DAA Decimal Adjust After Addition
- DAS decimal Adjust After Subtraction

打包的BCD表示形式不支持乘法和除法

示例
```asm
Live Demo
section	.text
   global _start        ;must be declared for using gcc

_start:	                ;tell linker entry point

   mov     esi, 4       ;pointing to the rightmost digit
   mov     ecx, 5       ;num of digits
   clc
add_loop:  
   mov 	al, [num1 + esi]
   adc 	al, [num2 + esi]
   aaa
   pushf
   or 	al, 30h
   popf
	
   mov	[sum + esi], al
   dec	esi
   loop	add_loop
	
   mov	edx,len	        ;message length
   mov	ecx,msg	        ;message to write
   mov	ebx,1	        ;file descriptor (stdout)
   mov	eax,4	        ;system call number (sys_write)
   int	0x80	        ;call kernel
	
   mov	edx,5	        ;message length
   mov	ecx,sum	        ;message to write
   mov	ebx,1	        ;file descriptor (stdout)
   mov	eax,4	        ;system call number (sys_write)
   int	0x80	        ;call kernel
	
   mov	eax,1	        ;system call number (sys_exit)
   int	0x80	        ;call kernel

section	.data
msg db 'The Sum is:',0xa	
len equ $ - msg			
num1 db '12345'
num2 db '23456'
sum db '     '
```



