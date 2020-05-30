---
title: "nasm汇编之过程 Procedures"
date: 2020-05-31T03:23:47+08:00
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

过程或子例程在汇编语言中非常重要，因为汇编语言程序往往会很大。程序由名称标识。
在此名称之后，将描述执行明确定义的作业的过程主体。该过程的结束由return语句指示。

语法
```asm
proc_name:
   procedure body
   ...
   ret
```
通过使用CALL指令从另一个函数调用该过程。 CALL指令应将被调用过程的名称作为参数，如下所示
```asm
CALL proc_name
```

示例
```asm
Live Demo
section	.text
   global _start        ;must be declared for using gcc
	
_start:	                ;tell linker entry point
   mov	ecx,'4'
   sub     ecx, '0'
	
   mov 	edx, '5'
   sub     edx, '0'
	
   call    sum          ;call sum procedure
   mov 	[res], eax
   mov	ecx, msg	
   mov	edx, len
   mov	ebx,1	        ;file descriptor (stdout)
   mov	eax,4	        ;system call number (sys_write)
   int	0x80	        ;call kernel
	
   mov	ecx, res
   mov	edx, 1
   mov	ebx, 1	        ;file descriptor (stdout)
   mov	eax, 4	        ;system call number (sys_write)
   int	0x80	        ;call kernel
	
   mov	eax,1	        ;system call number (sys_exit)
   int	0x80	        ;call kernel
sum:
   mov     eax, ecx
   add     eax, edx
   add     eax, '0'
   ret
	
section .data
msg db "The sum is:", 0xA,0xD 
len equ $- msg   

segment .bss
res resb 1
```

### 堆栈数据结构
堆栈是内存中类似数组的数据结构，可以在其中存储数据并从称为堆栈“顶部”的位置删除数据。
需要存储的数据被“推送”到堆栈中，要检索的数据被“弹出”到堆栈中。堆栈是LIFO数据结构，即首先存储的数据最后被检索

汇编语言为堆栈操作提供了两条指令：PUSH和POP。这些指令的语法如下
```asm
PUSH    operand
POP     address/register
```
堆栈段中保留的内存空间用于实现堆栈。寄存器SS和ESP（或SP）用于实现堆栈

SS：ESP寄存器指向堆栈顶部，该顶部指向插入到堆栈中的最后一个数据项，其中SS寄存器指向堆栈段的开头，而SP（或ESP）将偏移量堆栈段。

堆栈实现具有以下特征

- 只能将字或双字保存到堆栈中，而不是字节。
- 堆栈沿反方向增长，即朝着较低的内存地址增长
- 堆栈的顶部指向插入堆栈中的最后一个项目。它指向插入的最后一个字的低字节

在将寄存器的值用于某种用途之前将其存储在堆栈中；可以通过以下方式完成

```asm
; Save the AX and BX registers in the stack
PUSH    AX
PUSH    BX

; Use the registers for other purpose
MOV	AX, VALUE1
MOV 	BX, VALUE2
...
MOV 	VALUE1, AX
MOV	VALUE2, BX

; Restore the original values
POP	BX
POP	AX
```





