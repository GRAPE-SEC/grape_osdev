#include "Types.h"

void kPrintString(int iX, int iY, const char *pcString);
BOOL kInitializeKernel64Area(void);
BOOL kIsMemoryEnough(void);

// main function
void Main(void)
{
        DWORD i;

        kPrintString(0, 3, "C Language Kernel Start.....................[Pass]");

        // inspect memory size
        kPrintString(0, 4, "Minimum Memory Size Check...................[    ]");
        if (kIsMemoryEnough() == FALSE) {
                kPrintString(45, 4, "Fail");
                kPrintString(0, 5, "Not enough memory. MINT64 OS requires over 64MB.");
                while (1);
        } else {
                kPrintString(45, 4, "Pass");
        }

        // initialize kernel space of IA-32e mode to zero
        kPrintString(0, 5, "IA-32e Area Initialize......................[    ]");
        if (kInitializeKernel64Area() == FALSE) {
                kPrintString(45, 5, "Fail");
                kPrintString(0, 6, "Kernel area initialization failed.");
                while (1);
        }
        kPrintString(45, 5, "Pass");

        while (1);
}

// print string function
void kPrintString(int iX, int iY, const char *pcString)
{
        CHARACTER *pstScreen = (CHARACTER *)0xB8000;
        int i;

        pstScreen += (iY * 80) + iX;
        for (i = 0; pcString[i] != 0; i++)
                pstScreen[i].bCharacter = pcString[i];
}

// initialize kernel space of IA-32e mode
BOOL kInitializeKernel64Area(void)
{
        DWORD *pdwCurrentAddress;

        pdwCurrentAddress = (DWORD *)0x100000;

        while ((DWORD)pdwCurrentAddress < 0x600000) {
                *pdwCurrentAddress = 0x0000;

                if (*pdwCurrentAddress != 0)
                        return FALSE;

                pdwCurrentAddress++;
        }

        return TRUE;
}

// memory size check funcion
BOOL kIsMemoryEnough(void)
{
        DWORD *pdwCurrentAddress;

        pdwCurrentAddress = (DWORD *)0x100000;

        while ((DWORD)pdwCurrentAddress < 0x4000000) {
                *pdwCurrentAddress = 0x12345678;

                if (*pdwCurrentAddress != 0x12345678)
                        return FALSE;
                
                pdwCurrentAddress += (0x100000 / 4);
        }
        return TRUE;
}