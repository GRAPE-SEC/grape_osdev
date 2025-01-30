[ORG 0x00]                                                           ; 시작어드레스 설정
[BITS 16]                                                            ; 16bit로 코드 작성

SECTION .text                                                        ; 섹션 정의 방법 지정

START:
    mov ax, 0x1000                                                   ; DS, ES 레지스터에 시작어드레스 할당
    mov ds, ax
    mov es, ax

    cli                                                              ; 뭔 역할인지 모르겠음
    lgdt [GDTR]                                                      ; GDT 테이블 로드

    mov eax, 0x4000003B                                              ; CR0 컨트롤 레지스터 설정 초기화
    mov cr0, eax

    jmp dword 0x08: ( PROTECTEDMODE - $$ + 0x10000 )                 ; 보호모드 활성화

[BITS 32]                                                            ; 32bit로 코드 작성

PROTECTEDMODE:
    mov ax, 0x10                                                     ; DS, ES, FS, GS, SS, ESP, EBP 레지스터 초기화
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0xFFFE
    mov ebp, 0xFFFE

    push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )                     ; PRINTMESSAGE 매개변수 설정
    push 2
    push 0
    call PRINTMESSAGE                                                ; 보호 모드가 정상적으로 출력되었다는 메시지 출력
    add esp, 12                                                      ; 파라미터 초기화

    jmp $                                                            ; 현재 위치에서 무한루프

PRINTMESSAGE:
    push ebp                                                         ; 파라미터 설정
    mov ebp, esp
    push esi
    push edi
    push eax
    push ecx
    push edx

    mov eax, dword[ebp+12]                                           ; Y좌표 계산 후 EDI 레지스터에 할당
    mov esi, 160
    mul esi
    mov edi, eax

    mov eax, dword[ebp+8]                                            ; 실제 비디오 메모리 어드레스 계산하여 EDI 레지스터에 할당
    mov esi, 2
    mul esi
    add edi, eax

    mov esi, dword[ebp+16]                                           ; 문자열 어드레스로 ESI 레지스터 할당

.MESSAGELOOP:
    mov cl, byte[esi]                                                ; 문자열에서 문자 하나를 뽑아 CL 레지스터에 할당

    cmp cl, 0                                                        ; 더 이상 출력할 문자열이 없으면 함수 종료
    je .MESSAGEEND

    mov byte[edi+0xB8000], cl                                        ; 아니면 문자열 출력

    add esi, 1                                                       ; 다음 문자 어드레스로 이동
    add edi, 2

    jmp .MESSAGELOOP                                                 ; 반복

.MESSAGEEND:
    pop edx                                                          ; 파라미터 초기화
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret

align 8, db 0                                                        ; GDTR 자료구조 선언을 위한거라는데 무슨 역할인지는 모르겠음
dw 0x0000

GDTR:
    dw GDTEND - GDT - 1                                              ; GDT 테이블의 전체 크기
    dd ( GDT - $$ + 0x10000 )                                        ; GDT 테이블의 시작 어드레스

GDT:
    NULLDescriptor:                                                  ; NULL 디스크립터(기본값) 설정
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00
    
    CODEDESCRIPTOR:                                                  ; 보호 모드 커널용 코드 세그먼트 디스크립터 설정
        dw 0xFFFF
        dw 0x0000
        db 0x00
        db 0x9A
        db 0xCF
        db 0x00
    
    DATEDESCRIPTOR:                                                  ; 보호 모드 커널용 데이터 세그먼트 디스크립터 설정
        dw 0xFFFF
        dw 0x0000
        db 0x00
        db 0x92
        db 0xCF
        db 0x00
GDTEND:

SWITCHSUCCESSMESSAGE: db 'Switch to Protected Mode Complete.', 0

times 512 - ( $ - $$ ) db 0x00                                       ; 512바이트 중 나머지는 0으로 할당