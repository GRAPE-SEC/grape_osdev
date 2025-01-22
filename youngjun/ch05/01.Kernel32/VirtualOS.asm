[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x1000:START                ; CS = 0x1000 (VirtualOS image start address: 0x10000)

SECTORCOUNT: dw 0x0000          ; number of executed sectors
TOTALSECTORCOUNT equ 1024       ; same as "%define TOTALSECTORCOUNT 1024"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
    mov ax, cs
    mov ds, ax                  ; 0x1000 (virtual os image start address)
    mov ax, 0xB800
    mov es, ax                  ; video memory start address 0xb8000
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; implement code for each sector (case1: 2~1023, case2: 1024)
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    %assign i   0
    %rep TOTALSECTORCOUNT
        %assign i   i + 1

        mov ax, 2                   ; bytes per character
        mul word [SECTORCOUNT]      ; dx:ax = SECTORCOUNT x 2 == ax
        mov si, ax
        mov byte [es:si + (160*2)], '0' + (i % 10)  ; print '1'~'0' from the 3rd line
        add word [SECTORCOUNT], 1   ; increase sector count

        %if i == TOTALSECTORCOUNT
            jmp $                   ; infinite loop
        %else
            jmp (0x1000 + i * 0x20):0x0000  ; jump to start of the next sector
        %endif

        times (512 - ($ - $$) % 512) db 0x00
    %endrep