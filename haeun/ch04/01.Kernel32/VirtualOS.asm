[ORG 0x00]          
[BITS 16]           

SECTION .text       

jmp 0x1000:START    

SECTORCOUNT:    dw 0x0000   
TOTALSECTORCOUNT: equ 1024

START:
    mov ax, cs              
    mov ds, ax              
    mov ax, 0xB800          
    mov es, ax     

    %assign i 0                 
    ; i라는 변수를 지정하고 0으로 초기화
    %rep TOTALSECTORCOUNT       
    ; TOTALSECTORCOUNT에 저장된 값 만큼 아래 코드를 반복
        %assign i i + 1         

        mov ax, 2               
        mul word [ SECTORCOUNT ]
        mov si, ax              
        mov byte [ es: si + ( 160 * 2 ) ], '0' + (i % 10)
        add word [ SECTORCOUNT ], 1          

        %if i == TOTALSECTORCOUNT       
        ; 마지막 섹터라면
            jmp $                       ; 현재위치에서 무한 루프 수행
        %else
            jmp  ( 0x1000 + i * 0x20 ): 0x0000  ; 다음 섹터 오프셋으로 이동
        %endif                         

        times ( 512 - ( $ - $$ ) % 512 )  db  0x00  

    %endrep          
                                    
                                    