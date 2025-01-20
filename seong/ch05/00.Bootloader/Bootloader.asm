[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07C0:START

;;;;;환경 설정

TOTALSECTORCOUNT: dw 1024

SECTORNUMBER: db 0x02
HEADNUMBER: db 0x00
TRACKNUMBER: db 0x00

;;;;;;;;코드 영역

START:
    mov ax, 0x07c0
    mov ds,ax
    mov ax, 0xB800
    mov es,ax

    mov ax, 0x0000
    mov ss,ax
    mov sp,0xFFFE
    mov bp, 0xFFFE; 이 아래로 화면 초기화
    mov si, 0

.SCREENCLEARLOOP:
    mov byte [es:si],0
    mov byte [es:si+1], 0x0A
    add si, 2
    cmp si, 80 * 25 + 2
    jl .SCREENCLEARLOOP

;시작 메시지 출력

push MESSAGE1
push 0
push 0
call PRINTMESSAGE
add sp,6


;OS 이미지 로딩 메시지 출력
push IMAGELOADINGMESSAGE
push 1
push 0
call PRINTMESSAGE
add sp,6

;이미지 로딩

;디스크 리셋

RESETDISK:
    ;BIOS RESET function 사용
    mov ax,0
    mov dl,0
    int 0x13
    ;에러시 에러처리
    jc HANDLEDISKERROR

    ;디스크에서 읽어오기

    mov si, 0x1000
    mov es,si
    mov bx, 0x0000
    mov di, word [ TOTALSECTORCOUNT]


READDATA : 
    ; 모든 섹터를 읽었는지 확인
    cmp di, 0
    je READEND
    sub di, 0x1

    ;BIOS READ 

    mov ah, 0x02
    mov al, 0x1
    mov ch, byte [TRACKNUMBER]
    mov cl, byte [SECTORNUMBER]
    mov dh, byte [HEADNUMBER]
    mov dl, 0x00
    int 0x13
    jc HANDLEDISKERROR

    ;복사할 어드레스의 트랙, 헤드, 섹터 계산

    add si, 0x0020
    mov es, si

    mov al, byte [ SECTORNUMBER]
    add al, 0x01
    mov byte [SECTORNUMBER],al
    cmp al,19
    jl READDATA

    xor byte [HEADNUMBER], 0x01
    mov byte [SECTORNUMBER], 0x01

    cmp byte [HEADNUMBER], 0x00
    jne READDATA

    add byte [TRACKNUMBER], 0x01
    jmp READDATA


READEND: 
    push LOADINGCOMPLETEMESSAGE
    push 1
    push 20
    call PRINTMESSAGE
    add sp,6

    jmp 0x1000:0x0000

;함수 코드 영역

HANDLEDISKERROR:
    push DISKERRORMESSAGE
    push 1
    push 20
    call PRINTMESSAGE

    jmp $

PRINTMESSAGE:
    push bp
    mov bp,sp
    push es
    push si
    push di
    push ax
    push cx
    push dx
    mov ax, 0xB800
    mov es,ax
    

    ;비디오 어드레스 좌표 구하기

    mov ax, word [ bp + 6]
    mov si, 160
    mul si
    mov di, ax

    mov ax, word [bp + 4]
    mov si, 2
    mul si
    add di, ax

    mov si, word [bp + 8]

.MESSAGELOOP : 
    mov cl, byte [si]
    cmp cl, 0                   
    je .MESSAGEEND

    mov byte [es:di], cl       
    add si, 1                  
    add di, 2                  
    jmp .MESSAGELOOP


.MESSAGEEND:
    pop dx
    pop cx
    pop ax
    pop di
    pop si
    pop es

    pop bp
    ret

;;데이터 영역


MESSAGE1: db 'Bootloader loading is complete.', 0
DISKERRORMESSAGE: db 'Disk error occured.', 0
IMAGELOADINGMESSAGE: db 'loading image...', 0
LOADINGCOMPLETEMESSAGE: db 'Image loading is complete.', 0



times 510 - ($ - $$) db 0x00


db 0x55
db 0xAA