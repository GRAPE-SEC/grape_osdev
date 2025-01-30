; EntryPoints.s => 보호 모드 커널의 가장 앞부분에 위치한 코드 

[ORG 0x00]         
[BITS 16]          

SECTION .text      

START:
    mov ax, 0x1000  ; 보호 모드 엔트리 포인트의 시작 주소 : 0x1000
    mov ds, ax     
    mov es, ax     

    cli             ; 인터럽트가 발생하지 못하도록 설정
    lgdt [ GDTR ]       ; GDTR 자료구조를 프로세서에 설정하여 GDT 테이블을 로드

    ; 보호 모드로 진입
    ; Disable Paging, Disable Cache, Internal FPU, Disable Align Check, Enable ProtectedMode
    mov eax, 0x4000003B ; PG=0, CD=1, NW=0, AM=0, WP=0, NE=1, ET=1, TS=1, EM=0, MP=1, PE=1
    mov cr0, eax        

    jmp dword 0x08: ( PROTECTEDMODE - $$ + 0x10000 )


; 보호 모드로 진입
[BITS 32]           
PROTECTEDMODE:
    mov ax, 0x10    
    mov ds, ax      
    mov es, ax      
    mov fs, ax      
    mov gs, ax      

    ; 스택을 0x00000000 ~ 0x0000FFFF 영역에 64KB 크기로 생성
    mov ss, ax      
    mov esp, 0xFFFE 
    mov ebp, 0xFFFE 

    ; 보호 모드로 전환되었다는 메세지 출력 
    push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )    ; 출력할 메시지의 어드레스를 스택에 삽입
    push 2              ; 화면 Y 좌표
    push 0              ; 화면 X 좌표
    call PRINTMESSAGE   ; PRINTMESSAGE 함수 호출
    add esp, 12         ; 삽입한 파라미터 제거

    jmp $   ; 현재위치에서 무한 루프 수행


; 메시지를 출력하는 함수
;   PARAM: x좌표, y좌표, 문자열
PRINTMESSAGE:
    push ebp   
    mov ebp,esp
    push esi   
    push edi    
    push eax
    push ecx
    push edx

    ; X, Y의 좌표로 비디오 메모리의 어드레스를 계산

    mov eax, dword [ ebp + 12 ] ; Y 좌표 값 설정 
    mov esi, 160 ; 한 라인 (2*80 바이트)를 설정 
    mul esi ; Y 좌표 * 라인 수 
    mov edi, eax 

    mov eax, dword [ ebp + 8 ] ; X 좌표 값 설정 
    mov esi, 2 ; 한 문자 (2 바이트)를 설정 
    mul esi ; X 좌표 * 문자 
    add edi, eax ; edi = X 좌표 + Y 좌표 주소 = 메모리 주소 

    mov esi, dword [ ebp + 16 ] 

; 메시지 출력 루프
.MESSAGELOOP:               
    mov cl, byte [ esi ] 
    
    cmp cl, 0 ; cl이 비어있는지 확인 
    je .MESSAGEEND ; cl이 0이라면 문자열 끝이므로 종료 

    mov byte [ edi + 0x0B8000 ], cl ; 해당 메모리 주소에 문자 출력 

    add esi, 1 ; 다음 문자열 오프셋으로 이동 
    add edi, 2 ; 다음 문자열 + 속성값 오프셋으로 이동  

    jmp .MESSAGELOOP

.MESSAGEEND:
    pop edx 
    pop ecx 
    pop eax 
    pop edi 
    pop esi  
    pop ebp 
    ret 


; 아래의 데이터들을 8바이트에 맞춰 정렬
align 8, db 0

; GDTR의 끝을 8byte로 정렬
dw 0x0000

; GDTR 자료구조 정의
GDTR:
    dw GDTEND - GDT - 1         
    dd ( GDT - $$ + 0x10000 )   

;GDT 테이블 정의
GDT:
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

    ; 보호 모드 커널용 코드 세그먼트 디스크립터
    CODESCRIPTOR:
        dw 0xFFFF       ; Limit [15:0]
        dw 0x0000       ; Base [15:0]
        db 0x00         ; Base [23:16]
        db 0x9A         ; P=1, DPL=0, Code Segment, Execute/Read
        db 0xCF         ; G=1, D=1, L=0, Limit[19:16]
        db 0x00         ; Base [31:24]

    ; 보호 모드 커널용 데이터 세그먼트 디스크립터
    DATADESCRIPTOR:
        dw 0xFFFF       ; Limit [15:0]
        dw 0x0000       ; Base [15:0]
        db 0x00         ; Base [23:16]
        db 0x92         ; P=1, DPL=0, Data Segment, Read/Write
        db 0xCF         ; G=1, D=1, L=0, Limit[19:16]
        db 0x00         ; Base [31:24]
GDTEND:


; 보호 모드로 전환되었다는 메시지
SWITCHSUCCESSMESSAGE:   db 'Switch To Protected Mode Success!', 0

times 512 - ( $ - $$ )  db 0x00 