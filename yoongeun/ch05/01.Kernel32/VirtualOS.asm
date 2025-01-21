[ORG 0x00]
[BITS 16]

SECTION .text                                           ; 섹션 정의 방법 결정

jmp 0x1000:START                                        ; 코드 시작 위치 지정

SECTORCOUNT: dw 0x0000
TOTALSECTORCOUNT equ 1024                               ; 전역변수 설정

START:
    mov ax, cs
    mov ds, ax                                          ; DS 레지스터에 코드 세그먼트 값 저장
    mov ax, 0xB800
    mov es, ax                                          ; ES 레지스터에 비디오 메모리 어드레스 저장

    %assign i 0                                         ; 변수 i를 지정, 0으로 초기화
    %rep TOTALSECTORCOUNT                               ; for문 실행
        %assign i i+1 

        mov ax, 2
        mul word [SECTORCOUNT]
        mov si, ax                                      ; SI 레지스터에 섹터 위치를 좌표로 변환하여 저장
        
        mov byte [es:si + (160*2)], '0' + (i % 10)      ; 좌표값을 바탕으로 비디오 메모리에 i%10값을 출력
        add word [SECTORCOUNT], 1                       ; 다음 섹터로 이동

        %if i == TOTALSECTORCOUNT                       ; 마지막 섹터에서 무한 루프 수행
            jmp $
        %else
            jmp (0x1000 + i * 0x20):0x0000
        %endif

        times (512 - ($ - $$) % 512) db 0x00
    %endrep