---
title: "nasm汇编之逻辑指令 Logical Instructions"
date: 2020-05-31T02:16:58+08:00
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
处理器指令集提供指令AND，OR，XOR，TEST和NOT布尔逻辑，它们根据程序的需要测试，设置和清除位。

|序号| 指令 | 格式 |
|:---:|:---:|:---:|
|1|	AND|	AND operand1, operand2|
|2|	OR|	OR operand1, operand2|
|3|	XOR|	XOR operand1, operand2|
|4|	TEST|	TEST operand1, operand2|
|5|	NOT|	NOT operand1|
在所有情况下，第一个操作数都可以在寄存器或内存中。第二个操作数可以是寄存器/内存，也可以是立即数（常量）。
但是，内存到内存操作是不可能的。这些指令比较或匹配操作数的位，并设置CF，OF，PF，SF和ZF标志。


### and指令
AND指令用于通过执行按位AND运算来支持逻辑表达式。如果两个操作数的匹配位均为1，则按位AND运算将返回1，否则返回0

AND操作可用于清除一个或多个位。例如，假设BL寄存器包含00111010。如果需要将高阶位清除为零，则将其与0FH
```asm
AND	BL,   0FH   ; This sets BL to 0000 1010
```
如果要检查给定数字是奇数还是偶数，一个简单的测试将是检查数字的最低有效位。如果为1，则数字为奇数，否则为偶数。

假设数字在AL寄存器中，我们可以写
```asm
AND	AL, 01H     ; ANDing with 0000 0001
JZ    EVEN_NUMBER
```
示例
```asm
section .text
   global _start            ;must be declared for using gcc
	
_start:                     ;tell linker entry point
   mov   ax,   8h           ;getting 8 in the ax 
   and   ax, 1              ;and ax with 1
   jz    evnn
   mov   eax, 4             ;system call number (sys_write)
   mov   ebx, 1             ;file descriptor (stdout)
   mov   ecx, odd_msg       ;message to write
   mov   edx, len2          ;length of message
   int   0x80               ;call kernel
   jmp   outprog

evnn:   
  
   mov   ah,  09h
   mov   eax, 4             ;system call number (sys_write)
   mov   ebx, 1             ;file descriptor (stdout)
   mov   ecx, even_msg      ;message to write
   mov   edx, len1          ;length of message
   int   0x80               ;call kernel

outprog:

   mov   eax,1              ;system call number (sys_exit)
   int   0x80               ;call kernel

section   .data
even_msg  db  'Even Number!' ;message showing even number
len1  equ  $ - even_msg 
   
odd_msg db  'Odd Number!'    ;message showing odd number
len2  equ  $ - odd_msg
```

### or指令
OR指令用于通过执行按位或运算来支持逻辑表达式。如果来自任何一个或两个操作数的匹配位为1，则按位OR运算符将返回1。如果两个位均为零，则返回0。

或运算可用于设置一个或多个位。例如，假设AL寄存器包含0011 1010，则需要设置四个低位，您可以将其与值0000 1111（即FH）进行或运算。

### xor指令
XOR指令实现按位异或运算。当且仅当来自操作数的位不同时，XOR运算将结果位设置为1。如果操作数中的位相同（均为0或均为1），则将结果位清除为0。

将操作数与自身进行异或操作会将操作数更改为0。这用于清除寄存器。
```asm
XOR     EAX, EAX
```

### test指令
TEST指令的工作原理与AND运算相同，但与AND指令不同，它不更改第一个操作数。
因此，如果我们需要检查寄存器中的数字是偶数还是奇数，我们也可以使用TEST指令执行此操作，而无需更改原始数字

```asm
TEST    AL, 01H
JZ      EVEN_NUMBER
```

### not指令
NOT指令实现按位非运算。 NOT操作将操作数中的位取反。操作数可以在寄存器中，也可以在存储器中。


