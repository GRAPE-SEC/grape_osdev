[ORG 0x00]
[BITS 16]

SECTION .text

jmp 0x07c0:START    ; CS = 0x07c0 & jump to START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MINT64 OS config value
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TOTALSECTORCOUNT: dw 2   ; Size of MINT64 OS image except bootloader

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code Section
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START:
    mov ax, 0x07c0
    mov ds, ax      ; DS = 0x07c0 -> Data Segment: 0x7c00:0x0000~0x7c00:0xffff
    mov ax, 0xb800
    mov es, ax      ; ES = 0xb800 -> Extra Segment: 0xb8000:0x0000~0xb8000:0xffff

    ; Stack segment: 0x0000:0x0000~0x0000:0xffff
    mov ax, 0x0
    mov ss, ax      ; SS = 0
    mov sp, 0xFFFE
    mov bp, 0xFFFE

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Clear the screen, and set screen color to green
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si, 0

.SCREENCLEARLOOP:
    mov byte [es:si], 0         ; 1st byte = NULL character (clear the screen)
    mov byte [es:si + 1], 0x0A  ; 2nd byte = property (use green color)

    add si, 2                   ; next position
    cmp si, 80*25*2             ; end of the screen pixel? screen size is 80*25 (each pixel gets 2bytes)
    jl .SCREENCLEARLOOP

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Print start message
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push MESSAGE1               ; message to print
    push 0                      ; position X
    push 0                      ; position Y
    call PRINTMESSAGE           ; PrintMessage(message1, 0, 0)
    add sp, 6

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Print OS image loading message
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push IMAGELOADINGMESSAGE    ; message to print
    push 1                      ; position X
    push 0                      ; position Y
    call PRINTMESSAGE           ; PrintMessage(message1, 0, 0)
    add sp, 6

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Load OS image from disk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Reset disk before reading
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RESETDISK:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Call BIOS disk reset function
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ah, 0                   ; BIOS service number: reset (0)
    mov dl, 0                   ; drive number (floppy)
    int 0x13                    ; BIOS Disk I/O Service Interrupt

    jc HANDLEDISKERROR          ; Error handling

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Read sectors from disk
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov si, 0x1000    
    mov es, si                  ; Extra Segment=0x1000, 0x10000:0x0000 = OS image memory
                                ; ES:BX is the address to store data which has been read from memory
    mov bx, 0x0000

    mov di, word[TOTALSECTORCOUNT]  ; Sector counts to copy OS image

READDATA:
    ; Check whether all of sectors are written
    cmp di, 0
    je READEND
    sub di, 1

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Call BIOS disk read function
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov ah, 0x2                 ; BIOS service number: read sector (2)
    mov al, 0x1                 ; Sector counts to read
    mov ch, byte [TRACKNUMBER]  ; Track number to read
    mov dh, byte [HEADNUMBER]   ; Head number to read
    mov cl, byte [SECTORNUMBER] ; Sector number to read 
    mov dl, 0x0                 ; Drive number to read
    int 0x13                    ; BIOS Disk I/O Service Interrupt
    jc HANDLEDISKERROR          ; Error handling

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Calculate memory address to copy and track/head/sector number to read
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    add si, 0x0020
    mov es, si                  ; Add es register to 0x200 (512byte)

    mov al, byte [SECTORNUMBER]
    add al, 0x1
    mov byte [SECTORNUMBER], al
    cmp al, 19                  ; 1<= Sector number <= 18
    jl READDATA

    xor byte [HEADNUMBER], 0x1  ; Head number: 0 -> 1 -> 0 ...
    mov byte [SECTORNUMBER], 0x1; Reset sector number

    cmp byte [HEADNUMBER], 0x0  ; If head number was 1 before xor
    jne READDATA

    add byte [TRACKNUMBER], 0x1 ; increase track number
    jmp READDATA

READEND:
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Print the loading OS image success string
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    push LOADINGCOMPLETEMESSAGE
    push 1
    push 20
    call PRINTMESSAGE
    add sp, 6

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Jump to OS image
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp 0x1000:0x0000           ; OS image start address = 0x10000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Function implementations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
HANDLEDISKERROR:
    push DISKERRORMESSAGE
    push 1                      ; Y
    push 20                     ; X
    call PRINTMESSAGE

    jmp $                       ; infinite loop

PRINTMESSAGE:
    ; Function prologue
    push bp
    mov bp, sp

    ; Register backup
    push es
    push si
    push di
    push ax
    push cx
    push dx

    mov ax, 0xB800
    mov es, ax                  ; Video memory start address: 0xb8000

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Calculate the memory address of position X,Y
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; position Y is the height of screen (0 <= Y <= 79)
    mov ax, word [bp+6]          ; ax = Y
    mov si, 160                 ; 160: bytes per line (2 * 80)
    mul si                      ; dx:ax = ax * si = 160 x Y
    mov di, ax                  ; memory offset of Y

    ; position X is the width of screen (0 <= Y <= 24)
    mov ax, word [bp+6]          ; ax = X
    mov si, 2                   ; 2: bytes per pixel
    mul si                      ; dx:ax = ax * si = 2 x X
    add di, ax                  ; mnemory offset = Y + X

    mov si, word [bp+8]         ; string to print

.MESSAGELOOP:
    mov cl, byte [si]           ; each character of string
    cmp cl, 0                   ; check null termination
    je .MESSAGEEND              ; copy to memory completed

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

MESSAGE1: db 'MINT64 OS Boot Loader Start!', 0

DISKERRORMESSAGE: db 'Disk Error.', 0
IMAGELOADINGMESSAGE: db 'OS Image Loading...', 0
LOADINGCOMPLETEMESSAGE: db 'Kernel Loading Complete!', 0

SECTORNUMBER: db 0x02
HEADNUMBER: db 0x00
TRACKNUMBER: db 0x00

times 510 - ($ - $$) db 0x00

db 0x55
db 0xAA