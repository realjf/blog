---
title: "nasm汇编之循环 Loops"
date: 2020-05-31T03:23:13+08:00
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
JMP指令可用于实现循环。例如，以下代码段可用于执行循环主体10次

```asm
MOV	CL, 10
L1:
<LOOP-BODY>
DEC	CL
JNZ	L1
```
但是，处理器指令集包括一组用于实现迭代的循环指令。基本的LOOP指令具有以下语法
```asm
LOOP 	label
```
其中，label是标识目标指令的目标标签，如跳转指令中所述。 LOOP指令假定ECX寄存器包含循环计数。
当执行循环指令时，ECX寄存器递减，并且控制跳至目标标签，直到ECX寄存器的值（即计数器达到零）为止。

示例
```asm
Live Demo
section	.text
   global _start        ;must be declared for using gcc
	
_start:	                ;tell linker entry point
   mov ecx,10
   mov eax, '1'
	
l1:
   mov [num], eax
   mov eax, 4
   mov ebx, 1
   push ecx
	
   mov ecx, num        
   mov edx, 1        
   int 0x80
	
   mov eax, [num]
   sub eax, '0'
   inc eax
   add eax, '0'
   pop ecx
   loop l1
	
   mov eax,1             ;system call number (sys_exit)
   int 0x80              ;call kernel
section	.bss
num resb 1
```




