[ORG 0x00]
[BITS 16]

SECTION .text

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 16bit real mode kernel EP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
    mov ax, 0x1000
    mov ds, ax                  ; data segment = 0x10000~
    mov es, ax

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Enable A20 Gate
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; use BIOS interrupt service
    mov ax, 0x2401
    int 0x15

    jc .A20GATEERROR
    jmp .A20GATESUCCESS

.A20GATEERROR
    ; use system control port
    in al, 0x92
    or al, 0x2
    and al, 0xFE ; disable zero bit (prevent from reset)
    out 0x92, al

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; enter protection mode
; (cr0) disable paging/cache/fpu/align check
; (cr0) enable protected mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.A20GATESUCCESS:
    cli                         ; disable interrupt. interrupt handlers were not set in the 16bit real mode
    lgdt [GDTR]                 ; GDTR = start address of GDT info struct
    ; cr0 = 0100 0000 0000 0000 0000 0000 0011 1011
    ; EM(02)=0  ET(04)=1  MP(01)=1  TS(03)=1  NE(05)=1
    ; PG(31)=0  CD(30)=1, NW(29)=0  AM(18)=0  WP(16)=0
    ; PE(00)=1
    mov eax, 0x4000003B
    mov cr0, eax

    jmp dword 0x08: (PROTECTEDMODE - $$ + 0x10000)  ; CS=0x8 (GDT[1])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; protection mode code
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
PROTECTEDMODE:
    mov ax, 0x10
    mov ds, ax                  ; DS=0x10 (GDT[2])
    mov es, ax
    mov fs, ax
    mov gs, ax                  ; ES=FS=GS=0x10 (GDT[2])

    ; stack segment range 0x0000 ~ 0xffff (64kb = 2^16 byte)
    ; why 0xfffe, not 0xffff?: https://jsandroidapp.cafe24.com/xe/qna/5442
    mov ss, ax                  ; SS=0x10 (GDT[2])
    mov esp, 0xfffe
    mov ebp, 0xfffe

    push (SWITCHSUCCESSMESSAGE - $$ + 0x10000) ; SWITCHSUCCESSMESSAGE + 0x10000 is available
    push 2                      ; Y
    push 0                      ; X
    call PRINTMESSAGE
    add esp, 12

    jmp dword 0x8:0x10200       ; CS=0x8(GDT[1]), jump to 0x10200 (C kernel)
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; print function implementation
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTMESSAGE:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push eax
    push ecx
    push edx

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; calculate the video memory address of position X, Y
    ; size is 25 * 80
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, dword [ebp+12]         ; eax = Y
    mov esi, 160
    mul esi                         ; dx:ax = 2 * 80 * Y
    mov edi, eax

    mov eax, dword [ebp+8]          ; eax = X
    mov esi, 2
    mul esi                         ; dx:ax = 2 * X
    add edi, eax                    ; edi = 2*80*Y + 2*X

    mov esi, dword [ebp+16]         ; print string

.MESSAGELOOP:
    mov cl, byte [esi]          ; esi = string poitner
    cmp cl, 0                   ; null termination check
    je .MESSAGEEND

    mov byte [edi+0xb8000], cl  ; VGA memory start address=0xb8000, 0xb8000 + (2*80*Y + 2*X) <- character
    add esi, 1                  ; move to next character
    add edi, 2                  ; mov to next pixel
    jmp .MESSAGELOOP

.MESSAGEEND
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; data section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
align 8, db 0

dw 0x0000
GDTR:
    dw GDTEND - GDT - 1         ; size of GDT
    ; why subtract 1 from the size of GDT? https://wiki.osdev.org/Global_Descriptor_Table
    dd (GDT - $$ + 0x10000)     ; start address of GDT

GDT:
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00
    
    ; segment size (limit) = 0xffffff (almost 4MB); if G==1: size = size * 4KB(2^12) = almost 4GB
    ; base = 0x00000000

    ; limit[15:0]=0xffff
    ; base[31:16] = 0x0000
    ; base[39:32] = 0x00
    ; type[43:40] = 0xa (code segment, read/execute)
    ; S[44] = 1 (segment descriptor)
    ; DPL[46:45] = 0
    ; P[47] =1
    ; limit[51:48] = 0xf
    ; AVL[52] = 0
    ; L[53] = 0
    ; D/B[54] = 1 (32bit operation)
    ; G[55] = 1 (size x 4KB)
    ; base[63:56] = 0x0000
    CODEDESCRIPTOR:
        dw 0xffff               ; limit[15:0]
        dw 0x0000               ; base[31:16]
        db 0x00                 ; base[39:32]
        db 0x9a                 ; P[47]=1, DPL[46:45]=0, S[44]=1, type[43:40]=0xa
        db 0xcf                 ; G[55]=1, D/B[54]=1, L[53]=0, AVL[52]=0, limit[51, 48]=0xf
        db 0x00                 ; base[63:56]=0x0000
    
    ; segment size (limit) = 0xffffff (2^20 - 1 = 1MB - 1). if G==1: size = size * 4KB(2^12) = 4GB - 4KB
    ; base address = 0x00000000

    ; limit[15:0]=0xffff
    ; base[31:16] = 0x0000
    ; base[39:32] = 0x00
    ; type[43:40] = 0x2
    ; S[44] = 1
    ; DPL[46:45] = 0
    ; P[47] =1
    ; limit[51:48] = 0xf
    ; AVL[52] = 0
    ; L[53] = 0
    ; D/B[54] = 1
    ; G[55] = 1
    ; base[63:56] = 0x0000
    DATADESCRIPTOR:
        dw 0xffff               ; limit[15:0]
        dw 0x0000               ; base[31:16]
        db 0x00                 ; base[39:32]
        db 0x92                 ; P[47]=1, DPL[46:45]=0, S[44]=1, type[43:40]=0x2
        db 0xcf                 ; G[55]=1, D/B[54]=1, L[53]=0, AVL[52]=0, limit[51, 48]=0xf
        db 0x00                 ; base[63:56]=0x0000
    GDTEND:

SWITCHSUCCESSMESSAGE: db 'Successfully switched to protected mode.', 0

times 512 - ($ - $$) db 0x00