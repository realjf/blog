---
title: "nasm汇编之递归 Recursion"
date: 2020-05-31T06:13:15+08:00
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
递归过程是一个可以自我调用的过程。递归有两种：直接和间接。
在直接递归中，该过程调用自身，在间接递归中，第一个过程调用第二个过程，第二个过程依次调用第一个过程。

以下程序显示了如何使用汇编语言实现阶乘n。为了简化程序，我们将计算阶乘3
```asm
section	.text
   global _start         ;must be declared for using gcc
	
_start:                  ;tell linker entry point

   mov bx, 3             ;for calculating factorial 3
   call  proc_fact
   add   ax, 30h
   mov  [fact], ax
    
   mov	  edx,len        ;message length
   mov	  ecx,msg        ;message to write
   mov	  ebx,1          ;file descriptor (stdout)
   mov	  eax,4          ;system call number (sys_write)
   int	  0x80           ;call kernel

   mov   edx,1            ;message length
   mov	  ecx,fact       ;message to write
   mov	  ebx,1          ;file descriptor (stdout)
   mov	  eax,4          ;system call number (sys_write)
   int	  0x80           ;call kernel
    
   mov	  eax,1          ;system call number (sys_exit)
   int	  0x80           ;call kernel
	
proc_fact:
   cmp   bl, 1
   jg    do_calculation
   mov   ax, 1
   ret
	
do_calculation:
   dec   bl
   call  proc_fact
   inc   bl
   mul   bl        ;ax = al * bl
   ret

section	.data
msg db 'Factorial 3 is:',0xa	
len equ $ - msg			

section .bss
fact resb 1
```







