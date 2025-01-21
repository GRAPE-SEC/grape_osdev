[ORG 0x00]
[BITS 16]

SECTION .text                                                   ; 섹션 정의 방법 결정
jmp 0x07C0:START                                                ; 코드 시작 위치 결정

BOOTSUCCESSMESSAGE: db '64Bits OS Boot Loading...', 0
OSLOADINGMESSAGE: db 'OS image loading...', 0
TOTALSECTORCOUNT: dw 1024
SECTORNUMBER: db 0x02
HEADNUMBER: db 0x00
TRACKNUMBER: db 0x00
OSLOADINGCOMPLETEMESSEGE: db 'OS loading complete.', 0
DISKERRORMESSAGE: db 'Disk error is occured.', 0



START:
    mov ax, 0x07C0
    mov ds, ax                                                  ; 부트 로더 어드레스 지정
    mov ax, 0xB800
    mov es, ax                                                  ; 비디오 메모리 어드레스 지정

    mov ax, 0x0000
    mov ss, ax
    mov sp, 0xFFFE
    mov bp, 0xFFFE                                              ; 스택 세그먼트 어드레스 지정

    mov si, 0                                                   ; 문자열 레지스터 초기화



.SCREENCLEARLOOP:
    mov byte [es:si], 0
    mov byte [es:si + 1], 0x0A                                  ; 비디오 메모리에 검은 바탕, 진한 녹색, 공백으로 속성 및 출력값을 설정

    add si, 2
    cmp si, 80*25*2
    jl .SCREENCLEARLOOP                                         ; 모든 비디오 array에 대해 작업을 반복

    push BOOTSUCCESSMESSAGE
    push 0
    push 0                                                      ; 스택에 OS 부팅 성공 메시지 push
    call PRINTMESSAGE                                           ; 메시지 출력
    add sp, 6                                                   ; 스택 초기화

    push OSLOADINGMESSAGE
    push 1
    push 0                                                      ; 스택에 OS 이미지 복사 알림 메시지 push
    call PRINTMESSAGE                                           ; 메시지 출력
    add sp, 6                                                   ; 스택 초기화



RESETDISK:
    mov ah, 0
    mov dl, 0                                                   ; 디스크 관련 어드레스 초기화
    int 0x13
    jc HANDLEDISKERROR                                          ; 에러 발생 시 에러 처리로 이동

    mov si, 0x1000
    mov es, si
    mov bx, 0x0000                                              ; 디스크 메모리 공간 확보를 위한 어드레스 설정

    mov di, word[TOTALSECTORCOUNT]                              ; OS 이미지 섹터 수 설정



READDATA:
    cmp di, 0
    je READEND
    sub di, 0x1                                                 ; 반복 종료 조건

    mov ah, 0x02
    mov al, 0x1

    mov ch, byte [TRACKNUMBER]
    mov dh, byte [HEADNUMBER]
    mov cl, byte [SECTORNUMBER]
    mov dl, 0x00                                                ; OS 이미지 섹터 한 개씩 불러오기
    int 0x13
    jc HANDLEDISKERROR                                          ; 에러 발생 시 에러 처리로 이동

    add si, 0x0020
    mov es, si                                                  ; 다음 섹터로 넘어가기

    mov al, byte [SECTORNUMBER]
    add al, 0x01
    mov byte [SECTORNUMBER], al
    cmp al, 19
    jl READDATA                                                 ; 모든 섹터를 읽었는지 판단


    xor byte [HEADNUMBER], 0x01
    mov byte [SECTORNUMBER], 0x01
    cmp byte [HEADNUMBER], 0x00
    jne READDATA
    add byte [TRACKNUMBER], 0x01
    jmp READDATA                                                ; 모든 섹터를 읽었으면 다음 트랙으로 이동



READEND:
    push OSLOADINGCOMPLETEMESSEGE
    push 1
    push 24
    call PRINTMESSAGE                                           ; 모든 트랙을 읽고 OS 로딩이 완료되면 성공 메시지 출력
    add sp, 6                                                   ; 스택 초기화
    jmp 0x1000:0x0000                                           ; OS 실행



HANDLEDISKERROR:
    push DISKERRORMESSAGE
    push 1
    push 24
    call PRINTMESSAGE
    jmp $                                                       ; 에러 발생 시 메시지 출력 후 무한 로딩



PRINTMESSAGE:                                                   ; 메시지 출력 함수 ; x,y,문자열을 역순으로 받아 스택에서 pop해서 사용
    push bp
    mov bp, sp                                                  ; 스택 어드레스를 통해 스택 값에 접근

    push es
    push si
    push di
    push ax
    push cx
    push dx                                                     ; ES 레지스터부터 DX 레지스터까지 스택에 삽입

    mov ax, 0xB800
    mov es, ax                                                  ; 비디오 메모리 시작 어드레스에 접근

    mov ax, word [bp+6]
    mov si, 160
    mul si
    mov di, ax                                                  ; Y좌표로 라인 어드레스 계산 후 DI 레지스터에 저장

    mov ax, word [bp+4]
    mov si, 2
    mul si                                                      ; X좌표로 화면 X 어드레스 계산 후 AX 레지스터에 저장
    add di, ax                                                  ; 실제 비디오 어드레스 계산 후 DI 레지스터에 저장

    mov si, word [bp+8]                                         ; 출력할 문자열의 어드레스 설정



.MESSAGELOOP:                                                   ; 위에서 저장한 DI, SI 레지스터 값을 통해 화면에 메시지 출력
    mov cl, byte [si]
    cmp cl, 0
    je .MESSAGEEND                                              ; 반복 종료 조건

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
    ret                                                         ; 파라미터 초기화



times 510 - ($ - $$) db 0x00

db 0x55
db 0xAA