---
title: "nasm汇编之宏 Macros"
date: 2020-05-31T06:13:27+08:00
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

编写宏是确保使用汇编语言进行模块化编程的另一种方法。

- 宏是由名称分配的一系列指令，可以在程序中的任何位置使用。
- 在NASM中，宏使用％macro和％endmacro指令定义
- 宏以％macro指令开头，以％endmacro指令结尾

语法
```asm
%macro macro_name  number_of_params
<macro body>
%endmacro
```
其中，number_of_params指定数字参数，macro_name指定宏的名称。

通过使用宏名称和必要的参数来调用宏。当您需要在程序中多次使用某些指令序列时，可以将这些指令放在宏中并使用它，而不必一直写指令。

例如，程序的一个非常普遍的需求是在屏幕上写一个字符串。要显示字符串，需要以下说明序列
```asm
mov	edx,len	    ;message length
mov	ecx,msg	    ;message to write
mov	ebx,1       ;file descriptor (stdout)
mov	eax,4       ;system call number (sys_write)
int	0x80        ;call kernel
```
在以上显示字符串的示例中，INT 80H函数调用已使用寄存器EAX，EBX，ECX和EDX。
因此，每次需要在屏幕上显示时，都需要将这些寄存器保存在堆栈中，调用INT 80H，然后从堆栈中恢复寄存器的原始值。因此，编写两个用于保存和还原数据的宏可能会很有用

我们已经观察到，某些指令（如IMUL，IDIV，INT等）需要将某些信息存储在某些特定的寄存器中，甚至返回某些特定寄存器中的值。
如果程序已经使用这些寄存器来保存重要数据，则应将这些寄存器中的现有数据保存在堆栈中，并在执行指令后将其恢复。

示例
```asm
; A macro with two parameters
; Implements the write system call
   %macro write_string 2 
      mov   eax, 4
      mov   ebx, 1
      mov   ecx, %1
      mov   edx, %2
      int   80h
   %endmacro
 
section	.text
   global _start            ;must be declared for using gcc
	
_start:                     ;tell linker entry point
   write_string msg1, len1               
   write_string msg2, len2    
   write_string msg3, len3  
	
   mov eax,1                ;system call number (sys_exit)
   int 0x80                 ;call kernel

section	.data
msg1 db	'Hello, programmers!',0xA,0xD 	
len1 equ $ - msg1			

msg2 db 'Welcome to the world of,', 0xA,0xD 
len2 equ $- msg2 

msg3 db 'Linux assembly programming! '
len3 equ $- msg3
```







