---
title: "nasm汇编之常量 Constants"
date: 2020-05-31T02:09:10+08:00
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

NASM提供了多个定义常量的指令。在前面的章节中，我们已经使用过EQU指令。我们将特别讨论三个指令

- EQU
- %assign
- %define

### EQU指令
EQU指令用于定义常量。 EQU指令的语法如下
```asm
CONSTANT_NAME EQU expression
```
示例
```asm
TOTAL_STUDENTS equ 50
```
EQU语句的操作数可以是表达式

```asm
LENGTH equ 20
WIDTH  equ 10
AREA   equ length * width
```

示例
```asm
Live Demo
SYS_EXIT  equ 1
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1
section	 .text
   global _start    ;must be declared for using gcc
	
_start:             ;tell linker entry point
   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg1         
   mov edx, len1 
   int 0x80                
	
   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg2         
   mov edx, len2 
   int 0x80 
	
   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg3         
   mov edx, len3 
   int 0x80
   
   mov eax,SYS_EXIT    ;system call number (sys_exit)
   int 0x80            ;call kernel

section	 .data
msg1 db	'Hello, programmers!',0xA,0xD 	
len1 equ $ - msg1			

msg2 db 'Welcome to the world of,', 0xA,0xD 
len2 equ $ - msg2 

msg3 db 'Linux assembly programming! '
len3 equ $- msg3
```

### %assign指令
％assign指令可用于定义数字常量，例如EQU指令。该指令允许重新定义。例如，您可以将常量TOTAL定义为
```asm
%assign TOTAL 10
```
在代码的后面，您可以将其重新定义为
```asm
%assign  TOTAL  20
```
> 该指令区分大小写


### %define指令
％define指令允许定义数字常量和字符串常量。该指令类似于C中的#define。例如，您可以将常量PTR定义为
```asm
%define PTR [EBP+4]
```
该指令还允许重新定义，并且区分大小写








