[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x7c0:START                         ; CS = 0x7c0

START:
        mov ax, 0x7c0
        mov ds, ax                      ; DS = 0x7c0 (bootloader address: 0x7c00)
        mov ax, 0xb800
        mov es, ax                      ; ES = 0xb800 (video memory address: 0xb8000)
                                        ; about video memory - https://stackoverflow.com/questions/17367618/address-of-video-memory
        mov si, 0

.SCREENCLEARLOOP:                       ; clean the screen
        mov byte[es:si], 0      
        mov byte[es:si + 1], 0xa        ; light green (dark background)

        add si, 2                       ; move to next character (2byte)
        cmp si, 80 * 25 * 2
        jl .SCREENCLEARLOOP

        mov si, 0
        mov di, 0

.MESSAGELOOP:                           ; print the message to screen
        mov cl, byte[si + MESSAGE1]     ; cl = [0x7c00 + MESSAGE1_offset][si]
        cmp cl, 0                       ; null byte check
        je .MESSAGEEND                                                      

        mov byte[es:di], cl            ; video memory address + di = cl

        add si, 1
        add di, 2
        jmp .MESSAGELOOP

.MESSAGEEND:
        jmp $                           ; infinite loop

MESSAGE1: db 'Bootloader is executed successfully.', 0

times 510 - ($ - $$) db 0x00
; boot signature
db 0x55
db 0xAA