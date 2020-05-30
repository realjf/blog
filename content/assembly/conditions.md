---
title: "nasm汇编之条件判断 Conditions"
date: 2020-05-31T03:23:03+08:00
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

汇编语言中的条件执行是通过几个循环和分支指令来完成的。这些指令可以更改程序中的控制流。在两种情况下观察到条件执行

##### 无条件跳转
这是通过JMP指令执行的。条件执行通常涉及将控制权转移到不遵循当前执行指令的指令的地址。
控制权的转移可以是前进，执行新指令集，也可以是后退，重新执行相同的步骤

##### 有条件的跳转
这取决于条件由一组跳转指令j <condition>执行。条件指令通过中断顺序流程来转移控制，而它们通过更改IP中的偏移值来完成

### cmp指令
CMP指令比较两个操作数。它通常用于条件执行中。该指令基本上从另一个操作数中减去一个操作数，以比较操作数是否相等。
它不会干扰目标或源操作数。它与条件跳转指令一起用于决策。

语法
```asm
CMP destination, source
```
CMP比较两个数字数据字段。目标操作数可以在寄存器中或在内存中。源操作数可以是常量（立即数）数据，寄存器或内存

示例
```asm
CMP DX,	00  ; Compare the DX value with zero
JE  L7      ; If yes, then jump to label L7
.
.
L7: ...  
```
CMP通常用于比较计数器值是否已达到需要运行循环的次数。考虑以下典型条件
```asm
INC	EDX
CMP	EDX, 10	; Compares whether the counter has reached 10
JLE	LP1     ; If it is less than or equal to 10, then jump to LP1
```

### 无条件跳转
这是通过JMP指令执行的。条件执行通常涉及将控制权转移到不遵循当前执行指令的指令的地址。

语法
```asm
JMP	label
```

### 有条件跳转
如果在条件跳转中满足某些指定条件，则控制流将转移到目标指令。根据条件和数据有很多条件跳转指令

以下是对用于算术运算的有符号数据使用的条件跳转指令

| 指令 | 描述 | 测试标志位 |
|:---:|:---:|:---:|
|JE/JZ| 等于跳转/为零跳转 | ZF|
|JNE/JNZ| 不等于跳转/不为零跳转|ZF|
|JG/JNLE| 大于跳转/不小于等于跳转|OF,SF,ZF|
|JGE/JNL| 大于等于跳转/不小于跳转|OF,SF|
|JL/JNGE| 小于跳转/不大于等于跳转|OF,SF|
|JLE/JNG| 小于等于跳转/不大于跳转|OF,SF,ZF|

以下是对用于逻辑运算的无符号数据使用的条件跳转指令

| 指令 | 描述 | 测试标志位 |
|:---:|:---:|:---:|
|JE/JZ|	等于跳转/为零跳转	|ZF|
|JNE/JNZ| 不等于跳转/不为零跳转	|ZF|
|JA/JNBE|	Jump Above or Jump Not Below/Equal	|CF, ZF|
|JAE/JNB|	Jump Above/Equal or Jump Not Below	|CF|
|JB/JNAE|	Jump Below or Jump Not Above/Equal	|CF|
|JBE/JNA|	Jump Below/Equal or Jump Not Above	|AF, CF|


以下条件跳转指令具有特殊用途，并检查标志的值

| 指令 | 描述 | 测试标志位 |
|:---:|:---:|:---:|
JXCZ|	Jump if CX is Zero	|none|
|JC|	Jump If Carry	|CF|
|JNC|	Jump If No Carry|	CF|
|JO|	Jump If Overflow|	OF|
|JNO|	Jump If No Overflow	|OF|
|JP/JPE|	Jump Parity or Jump Parity Even	|PF|
|JNP/JPO|	Jump No Parity or Jump Parity Odd	|PF|
|JS|	Jump Sign (negative value)	|SF|
|JNS|	Jump No Sign (positive value)	|SF|


示例
```asm
section	.text
   global _start         ;must be declared for using gcc

_start:	                 ;tell linker entry point
   mov   ecx, [num1]
   cmp   ecx, [num2]
   jg    check_third_num
   mov   ecx, [num2]
   
	check_third_num:

   cmp   ecx, [num3]
   jg    _exit
   mov   ecx, [num3]
   
	_exit:
   
   mov   [largest], ecx
   mov   ecx,msg
   mov   edx, len
   mov   ebx,1	;file descriptor (stdout)
   mov   eax,4	;system call number (sys_write)
   int   0x80	;call kernel
	
   mov   ecx,largest
   mov   edx, 2
   mov   ebx,1	;file descriptor (stdout)
   mov   eax,4	;system call number (sys_write)
   int   0x80	;call kernel
    
   mov   eax, 1
   int   80h

section	.data
   
   msg db "The largest digit is: ", 0xA,0xD 
   len equ $- msg 
   num1 dd '47'
   num2 dd '22'
   num3 dd '31'

segment .bss
   largest resb 2  
```

