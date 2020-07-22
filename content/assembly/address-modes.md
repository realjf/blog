---
title: "nasm汇编之寻址模式 Addressing Modes"
date: 2020-05-31T01:05:08+08:00
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

大多数汇编语言指令都需要处理操作数。操作数地址提供了要处理的数据存储的位置。一些指令不需要操作数，而另一些指令则可能需要一个，两个或三个操作数

当一条指令需要两个操作数时，第一个操作数通常是目的地，可能是寄存器或存储器地址，第二个操作数是源。
源包含要传递的数据（立即寻址）或数据的地址（在寄存器或存储器中）。通常，操作后源数据保持不变。

寻址的三种基本模式是

- 寄存器寻址
- 立即寻址
- 内存寻址

### 寄存器寻址
在这种寻址模式下，寄存器包含操作数。根据指令，寄存器可以是第一操作数，第二操作数或两者。

```asm
MOV DX, TAX_RATE   ; Register in first operand
MOV COUNT, CX	   ; Register in second operand
MOV EAX, EBX	   ; Both the operands are in registers
```
由于寄存器之间的数据处理不涉及内存，因此可以最快地处理数据

### 立即寻址
立即数操作数具有常数值或表达式。当具有两个操作数的指令使用立即寻址时，第一个操作数可以是寄存器或存储器位置，而第二个操作数是立即数。第一个操作数定义数据的长度。

```asm
BYTE_VALUE  DB  150    ; A byte value is defined
WORD_VALUE  DW  300    ; A word value is defined
ADD  BYTE_VALUE, 65    ; An immediate operand 65 is added
MOV  AX, 45H           ; Immediate constant 45H is transferred to AX
```


### 直接内存寻址
在内存寻址模式下指定操作数时，通常需要直接访问主存储器，通常是数据段。这种寻址方式导致数据处理速度变慢。
为了找到数据在内存中的确切位置，我们需要段起始地址（通常在DS寄存器中找到）和偏移值。此偏移值也称为有效地址。

在直接寻址模式下，偏移量值直接在指令中指定，通常由变量名指示。汇编器计算偏移值并维护一个符号表，该表存储程序中使用的所有变量的偏移值。

在直接存储器寻址中，一个操作数引用一个存储器位置，另一个操作数引用一个寄存器。

```asm
ADD	BYTE_VALUE, DL	; Adds the register in the memory location
MOV	BX, WORD_VALUE	; Operand from the memory is added to register
```


### 直接偏移寻址
此寻址模式使用算术运算符修改地址。例如，查看以下定义数据表的定义
```asm
BYTE_TABLE DB  14, 15, 22, 45      ; Tables of bytes
WORD_TABLE DW  134, 345, 564, 123  ; Tables of words
```
以下操作将数据从存储器中的表访问到寄存器中
```asm
MOV CL, BYTE_TABLE[2]	; Gets the 3rd element of the BYTE_TABLE
MOV CL, BYTE_TABLE + 2	; Gets the 3rd element of the BYTE_TABLE
MOV CX, WORD_TABLE[3]	; Gets the 4th element of the WORD_TABLE
MOV CX, WORD_TABLE + 3	; Gets the 4th element of the WORD_TABLE
```

### 间接内存寻址
此寻址模式利用计算机的 Segment:Offset 寻址功能。通常，在方括号内编码的基址寄存器EBX，EBP（或BX，BP）和索引寄存器（DI，SI）用于内存引用。

间接寻址通常用于包含多个元素（如数组）的变量。阵列的起始地址存储在EBX寄存器中

以下代码段显示了如何访问变量的不同元素
```asm
MY_TABLE TIMES 10 DW 0  ; Allocates 10 words (2 bytes) each initialized to 0
MOV EBX, [MY_TABLE]     ; Effective Address of MY_TABLE in EBX
MOV [EBX], 110          ; MY_TABLE[0] = 110
ADD EBX, 2              ; EBX = EBX +2
MOV [EBX], 123          ; MY_TABLE[1] = 123
```

### mov 指令
该指令用于将数据从一个存储空间移动到另一个存储空间。 MOV指令采用两个操作数。

语法：
```asm
MOV  destination, source
```
MOV指令可能具有以下五种形式之一
```asm
MOV  register, register
MOV  register, immediate
MOV  memory, immediate
MOV  register, memory
MOV  memory, register
```


下表显示了一些常见的类型说明符

| 类型指定 | 寻址字节 |
|:---:|:---:|
| BYTE | 1 |
| WORD | 2 |
| DWORD| 4 | 
| QWORD | 8 |
| TBYTE | 10 |

示例
```asm
section	.text
   global _start     ;must be declared for linker (ld)
_start:             ;tell linker entry point
	
   ;writing the name 'Zara Ali'
   mov	edx,9       ;message length
   mov	ecx, name   ;message to write
   mov	ebx,1       ;file descriptor (stdout)
   mov	eax,4       ;system call number (sys_write)
   int	0x80        ;call kernel
	
   mov	[name],  dword 'Nuha'    ; Changed the name to Nuha Ali
	
   ;writing the name 'Nuha Ali'
   mov	edx,8       ;message length
   mov	ecx,name    ;message to write
   mov	ebx,1       ;file descriptor (stdout)
   mov	eax,4       ;system call number (sys_write)
   int	0x80        ;call kernel
	
   mov	eax,1       ;system call number (sys_exit)
   int	0x80        ;call kernel

section	.data
name db 'real jf! '
```



