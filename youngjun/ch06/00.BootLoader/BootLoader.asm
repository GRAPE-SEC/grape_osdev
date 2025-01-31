[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07c0:START    ; CS = 0x07c0 & jump to START (bootloader start address: 0x7c00)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; bootloader start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
    mov ax, 0x07c0
    mov ds, ax      ; DS = 0x07c0 -> data segment: 0x7c00:0x0000~0x7c00:0xffff
    mov ax, 0xb800
    mov es, ax      ; ES = 0xb800 -> extra segment: 0xb8000:0x0000~0xb8000:0xffff (VGA memory start address)

    ; stack segment: 0x0000:0x0000~0x0000:0xffff
    mov ax, 0x0
    mov ss, ax      ; SS = 0
    mov sp, 0xFFFE
    mov bp, 0xFFFE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; clear the screen, and set the font color to green
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si, 0

.SCREENCLEARLOOP: ; screen size: 80*25 (each pixel takes 2bytes)
    mov byte [es:si], 0         ; 1st byte = NULL character (clear the screen)
    mov byte [es:si + 1], 0x0A  ; 2nd byte = attribute (use green color)

    add si, 2                   ; next position
    cmp si, 80*25*2             ; check whether the end of the pixel has been reached.
    jl .SCREENCLEARLOOP

    ; print start message
    push BOOTLOADERSTARTMESSAGE ; start message address
    push 0                      ; position Y
    push 0                      ; position X
    call PRINTMESSAGE           ; PRINTMESSAGE(0, 0, BOOTALODERSTARTMESSAGE)
    add sp, 6

    ; print OS image loading message
    push IMAGELOADINGMESSAGE    ; os image loading message address
    push 1                      ; position Y
    push 0                      ; position X
    call PRINTMESSAGE           ; PRINTMESSAGE(0, 1, IMAGELOADINGMESSAGE)
    add sp, 6
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; load OS image from disk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RESETDISK: ; Reset disk before reading
    ; BIOS disk reset service
    mov ah, 0                   ; BIOS service number: reset (0)
    mov dl, 0                   ; drive number (floppy)
    int 0x13                    ; BIOS disk I/O service interrupt

    jc HANDLEDISKERROR          ; error handling

    ; read sectors from disk
    mov si, 0x1000
    mov es, si                  ; extra segment=0x1000, 0x10000:0x0000 = OS image memory
                                ; ES:BX is the memory location where data read from the disk is stored
    mov bx, 0x0000

    mov di, word[TOTALSECTORCOUNT]  ; number of sectors in the OS image

READDATA:
    ; check whether all sectors in the OS image have been read
    cmp di, 0
    je READEND
    sub di, 1

    ; BIOS disk read serivce
    mov ah, 0x2                 ; BIOS service number: read sector (2)
    mov al, 0x1                 ; sector counts to read
    mov ch, byte [TRACKNUMBER]  ; track number to read
    mov dh, byte [HEADNUMBER]   ; head number to read
    mov cl, byte [SECTORNUMBER] ; sector number to read
    mov dl, 0x0                 ; drive number to read
    int 0x13                    ; BIOS disk I/O aervice interrupt
    jc HANDLEDISKERROR          ; error handling

    ; calculate track/head/sector number and memory address to read/write
    add si, 0x0020
    mov es, si                  ; add 0x200 to es register (512byte)

    mov al, byte [SECTORNUMBER]
    add al, 0x1
    mov byte [SECTORNUMBER], al
    cmp al, 19                  ; 1 <= sector number <= 18
    jl READDATA

    xor byte [HEADNUMBER], 0x1  ; head number: 0 -> 1 -> 0 ...
    mov byte [SECTORNUMBER], 0x1; reset sector number

    cmp byte [HEADNUMBER], 0x0  ; if head number was 1 before xor
    jne READDATA

    add byte [TRACKNUMBER], 0x1 ; increase track number
    jmp READDATA

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; jump to OS kernel entrypoint
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

READEND:
    ; print the loading OS image success string
    push LOADCOMPLETEMESSAGE
    push 1                      ; Y
    push 24                     ; X
    call PRINTMESSAGE           ; PRINTMESSAGE(24, 1, LOADCOMPLETEMESSAGE)
    add sp, 6

    jmp 0x1000:0x0000 ; jump to OS image

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Disk Error Handler
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HANDLEDISKERROR:
    push DISKERRORMESSAGE
    push 1                      ; Y
    push 24                     ; X
    call PRINTMESSAGE           ; PRINTMESSAGE(24, 1, DISKERRORMESSAGE)

    jmp $                       ; infinite loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Print Function
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PRINTMESSAGE: ; PRINTMESSAGE(position X, position Y, message_address)
    ; function prologue
    push bp
    mov bp, sp

    ; register backup
    push es
    push si
    push di
    push ax
    push cx
    push dx

    mov ax, 0xB800
    mov es, ax                  ; Video memory start address: 0xb8000

    ; calculate the memory address of position X, Y
    ; string start offset = 80 * 2 * Y + 2 * X
    ; start memory address = VGA memory(0xB800) + string start offset

    ; position Y is the height of screen (0 <= Y <= 24)
    mov ax, word [bp+6]         ; ax = Y
    mov si, 160                 ; 160: bytes per line (2 * 80)
    mul si                      ; dx:ax = ax * si = 160 * Y == ax
    mov di, ax                  ; memory offset of Y

    ; position X is the width of screen (0 <= X <= 79)
    mov ax, word [bp+4]         ; ax = X
    mov si, 2                   ; 2: bytes per pixel
    mul si                      ; dx:ax = ax * si = 2 * X == ax
    add di, ax                  ; di = memory offset = (di)Y + (ax)X

    mov si, word [bp+8]         ; string address

.MESSAGELOOP:
    mov cl, byte [si]           ; each character of string
    cmp cl, 0                   ; check null termination
    je .MESSAGEEND

    mov byte [es:di], cl        ; copy character to es(video address) + di(offset)
    add si, 1                   ; move string pointer to next character
    add di, 2                   ; increase offset
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


BOOTLOADERSTARTMESSAGE: db 'Bootloader is loaded successfully.', 0
DISKERRORMESSAGE: db 'Disk error is occured.', 0
IMAGELOADINGMESSAGE: db 'Kernel image loading...', 0
LOADCOMPLETEMESSAGE: db 'Kernel loading complete!', 0


TOTALSECTORCOUNT: dw 1024   ; size of MINT64 OS image except bootloader

SECTORNUMBER: db 0x02
HEADNUMBER: db 0x00
TRACKNUMBER: db 0x00


times 510 - ($ - $$) db 0x00

db 0x55
db 0xAA