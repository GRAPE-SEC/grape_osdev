[ORG 0x00]  ; 코드의 시작 어드레스를 0x00으로 설정
[BITS 16]   ; 아래 코드를 16비트 코드로 설정 

SECTION .text   ; text 섹션 정의 

jmp 0x07C0:START ; CS 세그먼트 레지스터에 0x07C0 저장, START 레이블로 이동 

TOTALSECTORCOUNT:   dw  1    ; 부트로더를 제외한 MINT64 OS이미지의 크기
                            ; 최대 1152 섹터(0x90000byte)까지 가능

START: 
    mov ax, 0x07C0 ; 0x07C0: 부트로더의 시작 주소
    mov ds, ax 
    mov ax, 0xB800 ; 0xB800 : 비디오 메모리의 시작 주소   
    mov es, ax 

    ; 스택을 0x0000:0000 ~ 0x0000:FFFF 영역에 생성 
    mov ax, 0x0000 ; SS 시작 주소 
    mov ss, ax 
    mov sp, 0xFFFE ; SP 시작 주소 
    mov bp, 0xFFFE ; BP 설정 

    mov si, 0 ; si 초기화 

.SCREENCLEARLOOP:
    mov byte[ es:si ], 0 ; es 레지스터의 si 오프셋 주소에 0 저장 
    mov byte[ es:si + 1], 0x0A ; es 레지스터의 si+1 오프셋 주소에에 속성값 저장 
    add si, 2 ; 오프셋 값 2 증가 

    cmp si, 80 * 25 * 2 ; 오프셋 값이 화면 전체 크기보다 작다면 
    jl .SCREENCLEARLOOP ; 루프 반복 (jump if less)

    ; 상단 메시지 출력 
    push MESSAGE1 ; 출력할 메시지 주소 스택에 저장
    push 0 ; 화면 Y 좌표
    push 0 ; 화면 X 좌표 
    call PRINTMESSAGE ; 메시지 출력 함수 호출 
    add sp, 6 ; 스택에 삽입한 파라미터 제거 

    ; OS 이미지 로딩 메시지 출력 
    push IMAGELOADINGMESSAGE ; 출력할 메시지 주소 스택에 저장 
    push 1 ; 화면 Y 좌표
    push 0 ; 화면 X 좌표 
    call PRINTMESSAGE ; 메시지 출력 함수 호출
    add sp, 6 ; 스택에 삽입한 파라미터 제거 


; 디스크 초기화 
RESETDISK:
    ; BIOS Reset fucntion 호출 
    mov ax, 0 ; BIOS 서비스 번호 1
    mov dl, 0 ; 드라이브 번호 
    int 0x13
    jc HANDLEDISKERROR

    ; 디스크의 내용을 메모리로 복사할 주소 : 0x10000
    mov si, 0x1000
    mov es, si 
    mov bx, 0x0000 

    mov di, word [ TOTALSECTORCOUNT ] ; 복사할 OS 이미지의 섹터 수를 DI로 설정 

; 디스크 읽기 
READDATA:
    cmp di, 0 ; 복사할 OS의 이미지 섹터 수를 0과 비교 
    je READEND 
    sub di, 0x1 

    ; BIOS read function 호출
    mov ah, 0x02 ; BIOS 서비스 번호 2 (read sector)
    mov al, 0x1 ; 읽을 섹터 수 
    mov ch, byte [ TRACKNUMBER ] ; 트랙 번호 
    mov cl, byte [ SECTORNUMBER ] ; 섹터 번호 
    mov dh, byte [ HEADNUMBER ] ; 헤드 번호 
    mov dl, 0x00 ; 드라이브 번호 
    int 0x13
    jc HANDLEDISKERROR

    add si, 0x0020 ; 512 바이트 (0x200) 만큼 읽음 
    mov es, si 

    mov al, byte [ SECTORNUMBER ]
    add al, 0x01 ; 섹터 번호 1 증가 
    mov byte [ SECTORNUMBER ], al
    cmp al, 19 ; 섹터 번호 19 넘을 때까지 반복 
    jl READDATA

    xor byte [ HEADNUMBER ], 0x01 ; 헤드 번호 토글 
    mov byte [ SECTORNUMBER ], 0x01 ; 섹터 번호 1로 설정 

    cmp byte [ HEADNUMBER ], 0x00 ; 헤드 번호 0과 비교 
    jne READDATA 

    add byte [ TRACKNUMBER ], 0x01 ; 헤드 번호 0이라면 트랙 번호 1 증가 
    jmp READDATA 

READEND: 
    ; OS 이미지 완료 메시지 출력 
    push LOADINGCOMPLETEMESSAGE 
    push 1 ; Y 좌표 
    push 20 ; X 좌표 
    call PRINTMESSAGE
    add sp, 6 

    jmp 0x1000:0x0000 ; 로딩한 가상 OS 이미지 실행 

; 에러 처리 함수 
HANDLEDISKERROR: 
    push DISKERRORMESSAGE 
    push 1 
    push 20
    call PRINTMESSAGE
    add sp, 6 

    jmp $ ; 현재 위치에서 무한 루프 수행 

; 메시지 출력 함수 
PRINTMESSAGE: 
    push bp
    mov bp, sp

    push es
    push si 
    push di 
    push ax 
    push cx 
    push dx 

    mov ax, 0xB800 
    mov es, ax 

    mov ax, word [ bp + 6 ]
    mov si, 160 
    mul si 
    mov di, ax 

    mov ax, word [ bp + 4 ]
    mov si, 2 
    mul si 
    add di, ax 

    mov si, word [ bp + 8 ]

.MESSAGELOOP: 
    mov cl, byte [ si ] ; cl : cx 레지스터의 하위 1비트 
    
    cmp cl, 0 ; cl이 비어있는지 확인 
    je .MESSAGEEND ; cl이 0이라면 문자열 끝이므로 종료 

    mov byte [ es:di ], cl ; 시작 주소에 문자열 값 복사 

    add si, 1 ; 다음 문자열 오프셋으로 이동 
    add di, 2 ; 다음 문자열 + 속성값 오프셋으로 이동  

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

; 데이터 
MESSAGE1: db 'MINT64 OS Boot Loader Start!', 0 ; 출력할 메세지 정의, 마지막 값은 0으로 설정 

DISKERRORMESSAGE: db 'DISK Error', 0
IMAGELOADINGMESSAGE: db 'OS Image Loading ... ', 0
LOADINGCOMPLETEMESSAGE: db 'Loading Complete!', 0

; 디스크 읽기 관련 변수 
SECTORNUMBER: db 0x02 
HEADNUMBER: db 0x00 
TRACKNUMBER: db 0x00 

times 510 - ( $ - $$ ) db 0x00 
    ; $은 현재 라인의 어드레스 
    ; $$은 섹션(.text)의 시작 어드레스 
    ; $ - $$ 은 현재 섹션을 기준으로 하는 오프셋
    ; 510 - ($ - $$) : 현재 어드레스부터 510까지 
    ; 0x00으로 설정 
    ; times은 반복 수행한다는 뜻 
    ; 현재 위치에서 510까지 0x00으로 채움 

db 0x55
db 0xAA 

; 511, 512 어드레스에 0x55, 0xAA를 써서 부트로더라는 것을 표시함. 