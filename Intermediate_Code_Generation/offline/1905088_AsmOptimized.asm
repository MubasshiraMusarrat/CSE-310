;-------
;-------
.MODEL SMALL
.STACK 1000H
.DATA
	CR EQU 0DH
	LF EQU 0AH
.CODE
f PROC
	PUSH BP
	MOV BP, SP
	PUSH BX	;line 2: k declared
	PUSH [BP+-2]
;	PUSH 5
;	POP AX	;5 popped
	MOV AX, 5
;line  3: k=5
	MOV [BP+-2], AX
;line  4: while loop starts
	POP AX	;popped out k=5
L1:
	PUSH [BP+-2]
;line  4: k>0
;	PUSH 0
;	POP BX
	MOV BX, 0
	POP AX
	CMP AX, BX
	JG L2
	PUSH 0
	JMP L3
L2:
	PUSH 1
L3:
	POP AX
	CMP AX, 0
	JNE L5
	JMP L4
L5:
;line 5: a++
;	PUSH [BP+4]
;	POP AX
	MOV AX, [BP+4]
	PUSH AX
	INC AX
	MOV [BP+4],AX
	POP AX	;popped out a++
;line 6: k--
;	PUSH [BP+-2]
;	POP AX
	MOV AX, [BP+-2]
	PUSH AX
	DEC AX
	MOV [BP+-2],AX
	POP AX	;popped out k--
	JMP L1
L4:	;while loop ends
	PUSH 3
;line  8: 3*a
;	PUSH [BP+4]
;	POP BX
	MOV BX, [BP+4]
	POP AX
	IMUL BX
	PUSH AX
;line  8: 3*a-7
;	PUSH 7
;	POP BX
	MOV BX, 7
	POP AX
	SUB AX, BX
;	PUSH AX
;	POP AX
	MOV SP, BP	;restoring SP at the end of function
	POP BP
	RET 2
	PUSH [BP+4]
;	PUSH 9
;	POP AX	;9 popped
	MOV AX, 9
;line  9: a=9
	MOV [BP+4], AX
	POP AX	;popped out a=9
f ENDP
g PROC
	PUSH BP
	MOV BP, SP
	PUSH BX	;line 14: x declared
	PUSH BX	;line 14: i declared
	PUSH [BP+-2]
	PUSH [BP+6]
	CALL f
	PUSH AX	;pushed return value of f
;line  15: f(a)+a
;	PUSH [BP+6]
;	POP BX
	MOV BX, [BP+6]
	POP AX
	ADD AX, BX
	PUSH AX
;line  15: f(a)+a+b
;	PUSH [BP+4]
;	POP BX
	MOV BX, [BP+4]
	POP AX
	ADD AX, BX
;	PUSH AX
;	POP AX	;f(a)+a+b popped
;line  15: x=f(a)+a+b
	MOV [BP+-2], AX
	POP AX	;popped out x=f(a)+a+b
	PUSH [BP+-4]
;	PUSH 0
;	POP AX	;0 popped
	MOV AX, 0
;line  17: i=0
	MOV [BP+-4], AX
;line  17: for loop starts
	POP AX	;popped out i=0
L6:
	PUSH [BP+-4]
;line  17: i<7
;	PUSH 7
;	POP BX
	MOV BX, 7
	POP AX
	CMP AX, BX
	JL L7
	PUSH 0
	JMP L8
L7:
	PUSH 1
L8:
	POP AX	;popped out i<7
	CMP AX,0
	JNE L10
	JMP L9
L10:
	PUSH [BP+-4]
	PUSH [BP+-4]
;line  19: i%3
;	PUSH 3
;	POP BX
	MOV BX, 3
	POP AX
	XOR DX,DX
	IDIV BX
	MOV AX,DX
	PUSH AX
;line  19: i%3==0
;	PUSH 0
;	POP BX
	MOV BX, 0
	POP AX
	CMP AX, BX
	JE L11
	PUSH 0
	JMP L12
L11:
	PUSH 1
;line  19: evaluating if
L12:
	POP AX
	CMP AX, 0
	JNE L14
	JMP L13
L14:
	PUSH [BP+-2]
	PUSH [BP+-2]
;line  20: x+5
;	PUSH 5
;	POP BX
	MOV BX, 5
	POP AX
	ADD AX, BX
;	PUSH AX
;	POP AX	;x+5 popped
;line  20: x=x+5
	MOV [BP+-2], AX
	POP AX	;popped out x=x+5
	JMP L15
L13:
	PUSH [BP+-2]
	PUSH [BP+-2]
;line  23: x-1
;	PUSH 1
;	POP BX
	MOV BX, 1
	POP AX
	SUB AX, BX
;	PUSH AX
;	POP AX	;x-1 popped
;line  23: x=x-1
	MOV [BP+-2], AX
	POP AX	;popped out x=x-1
;line 17: i++
L15:
	POP AX
	PUSH AX
	INC AX
	MOV [BP+-4],AX
	POP AX
	JMP L6
L9:	;for loop terminates
;	PUSH [BP+-2]
;	POP AX
	MOV AX, [BP+-2]
	MOV SP, BP	;restoring SP at the end of function
	POP BP
	RET 4
g ENDP
main PROC
	MOV AX, @DATA
	MOV DS, AX
	MOV BP, SP
	PUSH BX	;line 31: a declared
	PUSH BX	;line 31: b declared
	PUSH BX	;line 31: i declared
	PUSH [BP+-2]
;	PUSH 1
;	POP AX	;1 popped
	MOV AX, 1
;line  32: a=1
	MOV [BP+-2], AX
	POP AX	;popped out a=1
	PUSH [BP+-4]
;	PUSH 2
;	POP AX	;2 popped
	MOV AX, 2
;line  33: b=2
	MOV [BP+-4], AX
	POP AX	;popped out b=2
	PUSH [BP+-2]
	PUSH [BP+-2]
	PUSH [BP+-4]
	CALL g
;	PUSH AX	;pushed return value of g
;	POP AX	;g(a,b) popped
;line  34: a=g(a,b)
	MOV [BP+-2], AX
;line  35: println(a);
	POP AX	;popped out a=g(a,b)
	PUSH [BP+-2]
	CALL PRINT_OUTPUT
	CALL NEW_LINE
	PUSH [BP+-6]
;	PUSH 0
;	POP AX	;0 popped
	MOV AX, 0
;line  36: i=0
	MOV [BP+-6], AX
;line  36: for loop starts
	POP AX	;popped out i=0
L16:
	PUSH [BP+-6]
;line  36: i<4
;	PUSH 4
;	POP BX
	MOV BX, 4
	POP AX
	CMP AX, BX
	JL L17
	PUSH 0
	JMP L18
L17:
	PUSH 1
L18:
	POP AX	;popped out i<4
	CMP AX,0
	JNE L20
	JMP L19
L20:
	PUSH [BP+-2]
;	PUSH 3
;	POP AX	;3 popped
	MOV AX, 3
;line  37: a=3
	MOV [BP+-2], AX
;line  38: while loop starts
	POP AX	;popped out a=3
L21:
	PUSH [BP+-2]
;line  38: a>0
;	PUSH 0
;	POP BX
	MOV BX, 0
	POP AX
	CMP AX, BX
	JG L22
	PUSH 0
	JMP L23
L22:
	PUSH 1
L23:
	POP AX
	CMP AX, 0
	JNE L25
	JMP L24
L25:
;line 39: b++
;	PUSH [BP+-4]
;	POP AX
	MOV AX, [BP+-4]
	PUSH AX
	INC AX
	MOV [BP+-4],AX
	POP AX	;popped out b++
;line 40: a--
;	PUSH [BP+-2]
;	POP AX
	MOV AX, [BP+-2]
	PUSH AX
	DEC AX
	MOV [BP+-2],AX
	POP AX	;popped out a--
	JMP L21
L24:	;while loop ends
;line 36: i++
;	PUSH [BP+-6]
;	POP AX
	MOV AX, [BP+-6]
	PUSH AX
	INC AX
	MOV [BP+-6],AX
	POP AX
	JMP L16
;line  43: println(a);
L19:	;for loop terminates
	PUSH [BP+-2]
	CALL PRINT_OUTPUT
;line  44: println(b);
	CALL NEW_LINE
	PUSH [BP+-4]
	CALL PRINT_OUTPUT
;line  45: println(i);
	CALL NEW_LINE
	PUSH [BP+-6]
	CALL PRINT_OUTPUT
	CALL NEW_LINE
	PUSH 0
	MOV AH, 4CH
	INT 21H
	MOV AH, 4CH
	INT 21H
main ENDP
NEW_LINE PROC
	PUSH AX
	PUSH DX
	MOV AH, 2
	MOV DL, CR
	INT 21H
	MOV AH, 2
	MOV DL, LF
	INT 21H
	POP DX
	POP AX
	RET
NEW_LINE ENDP
PRINT_OUTPUT PROC NEAR;print what is in AX
	PUSH BP
	MOV BP,SP
	MOV BX, [BP+4]
	CMP BX, 0  ;(BX<-1) for positive number
	JGE PRINT_POSITIVE
	MOV AH, 2   ;(AH<-2) for negative number
	MOV DL, '-'
	INT 21H
	NEG BX
PRINT_POSITIVE:
	MOV AX, BX
	MOV CX, 0
PUSH_WHILE:
	XOR DX, DX
	MOV BX, 10
	DIV BX
	PUSH DX
	INC CX
	CMP AX, 0
	JE PUSH_END_WHILE
	JMP PUSH_WHILE
PUSH_END_WHILE:
	MOV AH, 2
POP_WHILE:
	POP DX
	ADD DL, '0'
	INT 21H
	DEC CX
	CMP CX, 0
	JLE END_POP_WHILE
	JMP POP_WHILE
END_POP_WHILE:
	POP BP
	RET 2
PRINT_OUTPUT ENDP
END MAIN
