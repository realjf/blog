---
title: "nasm汇编之算术指令 Arithmetic Instructions"
date: 2020-05-31T02:15:46+08:00
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

### inc 指令
INC指令用于将操作数加1。它适用于可以在寄存器或内存中的单个操作数

语法
```asm
INC destination
```
操作数目的地可以是8位，16位或32位操作数

示例
```asm
INC EBX	     ; Increments 32-bit register
INC DL       ; Increments 8-bit register
INC [count]  ; Increments the count variable
```

### dec指令
DEC指令用于将操作数减1。它对可以在寄存器或内存中的单个操作数起作用

语法
```asm
DEC destination
```
操作数目的地可以是8位，16位或32位操作数。

示例
```asm
segment .data
   count dw  0
   value db  15
	
segment .text
   inc [count]
   dec [value]
	
   mov ebx, count
   inc word [ebx]
	
   mov esi, value
   dec byte [esi]
```

### add和sub指令
ADD和SUB指令用于对字节，字和双字大小的二进制数据进行简单的加/减，即分别用于添加或减去8位，16位或32位操作数

语法
```asm
ADD/SUB	destination, source
```
ADD / SUB指令可以在

- 寄存器到寄存器
- 内存到寄存器
- 寄存器到内存
- 寄存器到常量
- 内存到常量

与其他指令一样，使用ADD/SUB指令也无法进行存储器到存储器的操作。 ADD或SUB操作设置或清除溢出和进位标志。

下面的示例将要求用户输入两位数字，分别将这些数字存储在EAX和EBX寄存器中，将这些值相加，将结果存储在存储位置“ res”中，最后显示结果。
```asm
SYS_EXIT  equ 1
SYS_READ  equ 3
SYS_WRITE equ 4
STDIN     equ 0
STDOUT    equ 1

segment .data 

   msg1 db "Enter a digit ", 0xA,0xD 
   len1 equ $- msg1 

   msg2 db "Please enter a second digit", 0xA,0xD 
   len2 equ $- msg2 

   msg3 db "The sum is: "
   len3 equ $- msg3

segment .bss

   num1 resb 2 
   num2 resb 2 
   res resb 1    

section	.text
   global _start    ;must be declared for using gcc
	
_start:             ;tell linker entry point
   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg1         
   mov edx, len1 
   int 0x80                

   mov eax, SYS_READ 
   mov ebx, STDIN  
   mov ecx, num1 
   mov edx, 2
   int 0x80            

   mov eax, SYS_WRITE        
   mov ebx, STDOUT         
   mov ecx, msg2          
   mov edx, len2         
   int 0x80

   mov eax, SYS_READ  
   mov ebx, STDIN  
   mov ecx, num2 
   mov edx, 2
   int 0x80        

   mov eax, SYS_WRITE         
   mov ebx, STDOUT         
   mov ecx, msg3          
   mov edx, len3         
   int 0x80

   ; moving the first number to eax register and second number to ebx
   ; and subtracting ascii '0' to convert it into a decimal number
	
   mov eax, [num1]
   sub eax, '0'
	
   mov ebx, [num2]
   sub ebx, '0'

   ; add eax and ebx
   add eax, ebx
   ; add '0' to to convert the sum from decimal to ASCII
   add eax, '0'

   ; storing the sum in memory location res
   mov [res], eax

   ; print the sum 
   mov eax, SYS_WRITE        
   mov ebx, STDOUT
   mov ecx, res         
   mov edx, 1        
   int 0x80

exit:    
   
   mov eax, SYS_EXIT   
   xor ebx, ebx 
   int 0x80
```


### mul/imul 指令
有两条指令用于将二进制数据相乘。 
MUL（乘法）指令处理无符号的数据，
而IMUL（整数乘法）则处理有符号的数据。两条指令都影响进位和溢出标志

语法
```asm
MUL/IMUL multiplier
```
这两种情况下，被乘数都将在一个累加器中，具体取决于被乘数和乘数的大小，并且根据操作数的大小，生成的乘积还存储在两个寄存器中。

以下部分说明了三种不同情况下的MUL指令

| 序号 | 情景 |
|:---:|:---:|
| 1 | 当两个字节相乘时 - 被乘数在AL寄存器中，而乘数是存储器中或另一个寄存器中的一个字节。该结果使用AX。乘积的高8位存储在AH中，低8位存储在AL中。|
| 2 | 当两个单字值相乘时 - 被乘数应位于AX寄存器中，并且乘数是内存或其他寄存器中的一个字。例如，对于MUL DX这样的指令，必须将乘数存储在DX中并将被乘数存储在AX中。结果乘积是一个双字，将需要两个寄存器。高阶（最左侧）部分存储在DX中，而低阶（最右侧）部分存储在AX中。 |
| 3 | 两个双字值相乘时 - 当两个双字值相乘时，被乘数应位于EAX中，并且乘数是存储在存储器或另一个寄存器中的双字值。生成的乘积存储在EDX：EAX寄存器中，即，高32位存储在EDX寄存器中，低32位存储在EAX寄存器中。|

示例
```asm
MOV AL, 10
MOV DL, 25
MUL DL
...
MOV DL, 0FFH	; DL= -1
MOV AL, 0BEH	; AL = -66
IMUL DL
```

### div/idiv指令
除法运算生成两个元素-商和余数。如果是乘法，则不会发生溢出，因为使用了双倍长度寄存器来保持乘积。
但是，在除法的情况下，可能会发生溢出。如果发生溢出，处理器将产生中断。

DIV（除法）指令用于无符号数据，IDIV（整数除法）用于有符号数据

语法
```asm
DIV/IDIV	divisor
```
商和余数在累加器中。两条指令都可以使用8位，16位或32位操作数。该操作影响所有六个状态标志。下一节说明了不同操作数大小的三种除法情况

| 序号 | 情景 |
| :---:|:---:|
| 1| 除数为1字节时 - 假定被除数位于AX寄存器（16位）中。除法后，商进入AL寄存器，其余部分进入AH寄存器 |
| 2| 除数是2字节时 - 假定分频器为DX：AX寄存器中的32位长。高位16位在DX中，低位16位在AX中，除法后，16位的商进入AX寄存器，而16位的余数进入DX寄存器。|
| 3| 除数是4字节时 - 假定在EDX：EAX寄存器中分红为64位长。高位32位在EDX中，低位32位在EAX中。除法后，32位的商进入EAX寄存器，而32位的余数进入EDX寄存器。|

示例
```asm
Live Demo
section	.text
   global _start    ;must be declared for using gcc
	
_start:             ;tell linker entry point
   mov	ax,'8'
   sub     ax, '0'
	
   mov 	bl, '2'
   sub     bl, '0'
   div 	bl
   add	ax, '0'
	
   mov 	[res], ax
   mov	ecx,msg	
   mov	edx, len
   mov	ebx,1	;file descriptor (stdout)
   mov	eax,4	;system call number (sys_write)
   int	0x80	;call kernel
	
   mov	ecx,res
   mov	edx, 1
   mov	ebx,1	;file descriptor (stdout)
   mov	eax,4	;system call number (sys_write)
   int	0x80	;call kernel
	
   mov	eax,1	;system call number (sys_exit)
   int	0x80	;call kernel
	
section .data
msg db "The result is:", 0xA,0xD 
len equ $- msg   
segment .bss
res resb 1
```







