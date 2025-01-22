[ORG 0x00]  ; 코드의 시작 어드레스를 0x00으로 설정
[BITS 16]   ; 아래 코드를 16비트 코드로 설정 

SECTION .text   ; text 섹션 정의 

jmp 0x07C0:START ; CS 세그먼트 레지스터에 0x07C0 저장, START 레이블로 이동 

START: 
    mov ax, 0x07C0 ; ax에 부트로더의 시작 주소 저장 
    mov ds, ax ; ds에 ax 복사
    mov ax, 0xB800 ; ax에 비디오 어드레스 시작 주소 저장  
    mov es, ax ; es에 ax 복사 

    mov si, 0 ; si 초기화 

.SCREENCLEARLOOP:
    mov byte[ es:si ], 0 ; es 레지스터의 si 오프셋 주소에에 0 저장 
    mov byte[ es:si + 1], 0x0A ; es 레지스터의 si+1 오프셋 주소에에 속성값 저장 
    add si, 2 ; 오프셋 값 2 증가 

    cmp si, 80 * 25 * 2 ; 오프셋 값이 화면 전체 크기보다 작다면 
    jl .SCREENCLEARLOOP ; 루프 반복 (jump if less)

    mov si, 0 ; si (문자열의 오프셋) 초기화 
    mov di, 0 ; di (출력할 부분 메모리 오프셋) 초기화 

.MESSAGELOOP: 
    mov cl, byte [ si + MESSAGE1 ] ; cl : cx 레지스터의 하위 1비트 
    
    cmp cl, 0 ; cl이 비어있는지 확인 
    je .MESSAGEEND ; cl이 0이라면 문자열 끝이므로 종료 

    mov byte [ es:di ], cl ; 시작 주소에 문자열 값 복사 

    add si, 1 ; 다음 문자열 오프셋으로 이동 
    add di, 2 ; 다음 문자열 + 속성값 오프셋으로 이동  

    jmp .MESSAGELOOP

.MESSAGEEND: 

MESSAGE1: db 'Hello Haeun World~!', 0 ; 출력할 메세지 정의, 마지막 값은 0으로 설정 


jmp $ ; 현재 위치에서 무한 루프 실행 

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