---
title: "nasm汇编之内存段 Memory Segments"
date: 2020-05-31T00:33:36+08:00
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

汇编程序的三个节.data、.bss、.text。这些部分也代表各种内存段。

如果将section关键字替换为segment，则会得到相同的结果。试试下面的代码

```asm
segment .text	   ;code segment
   global _start    ;must be declared for linker 
	
_start:	           ;tell linker entry point
   mov edx,len	   ;message length
   mov ecx,msg     ;message to write
   mov ebx,1	   ;file descriptor (stdout)
   mov eax,4	   ;system call number (sys_write)
   int 0x80	   ;call kernel

   mov eax,1       ;system call number (sys_exit)
   int 0x80	   ;call kernel

segment .data      ;data segment
msg	db 'Hello, world!',0xa   ;our dear string
len	equ	$ - msg          ;length of our dear string
```

### 内存段
分段存储器模型将系统存储器分为独立的分段组，这些分段由位于分段寄存器中的指针引用。每个细分用于包含特定类型的数据。
一个段用于包含指令代码，另一段用于存储数据元素，第三段用于保留程序堆栈。

- data段 它由.data节和.bss表示。 
    - .data节用于声明存储区，在该存储区中为程序存储了数据元素。声明数据元素后，无法扩展此部分，并且在整个程序中它保持静态
    - .bss部分还是静态存储器部分，其中包含用于稍后在程序中声明的数据的缓冲区。该缓冲存储器为零。
- code段 它由.text部分表示。这在内存中定义了存储指令代码的区域。这也是一个固定区域
- stack 该段包含传递给程序中的函数和过程的数据值。







