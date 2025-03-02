#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <io.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>

#define BYTEOFSECTOR 512

int AdjustInSectorSize(int iFd, int iSourceSize);
void WriteKernelInformation(int iTargetFd, int iKernelSectorCount);
int CopyFile(int iSourceFd, int iTargetFd);



int main(int argc, char *argv[])
{
        int iSourceFd;
        int iTargetFd;
        int iBootLoaderSize;
        int iKernel32SectorCount;
        int iSourceSize;

        if (argv < 3){
                fprintf(stderr, "[ERROR] ImageMaker.exe BooLoader.bin Kernel32.bin\n");
                exit(-1);
        }

        if ((iTargetFd = open("Disk.img", O_RDWR | O_CREAT | O_TRUNC | O_BINARY, S_IREAD | S_IWRITE)) == -1){
                fprintf(stderr, "[ERROR] Disk.img open fail.\n");
                exit(-1);
        }

        //-------------------------------------------------
        // copy bootloader to Disk.img
        //-------------------------------------------------
        printf("[INFO] Copy boot loader to image file\n");
        if ((iSourceFd = open(argv[1], O_RDONLY | O_BINARY)) == -1){
                fprintf(stderr, "[ERROR] %s open fail\n", argv[1]);
                exit(-1);
        }

        iSourceSize = CopyFile(iSourceFd, iTargetFd);
        close(iSourceFd);

        // pad with 0 to the rest of Disk.img to fit the sector size(512byte)
        iBootLoaderSize = AdjustInSectorSize(iTargetFd, iSourceSize);
        printf("[INFO] %s size = [%d] and sector count = [%d]\n", argv[1], iSourceSize, iBootLoaderSize);

        //-------------------------------------------------
        // concatnate 32bit kernel image with Disk.img
        //-------------------------------------------------
        printf("[INFO] Copy protected mode kernel to image file\n");
        if ((iSourceFd = open(argv[2], O_RDONLY|O_BINARY)) == -1){
                fprintf(stderr, "[ERROR] %s open fail\n", argv[2]);
                exit(-1);
        }

        iSourceSize = CopyFile(iSourceFd, iTargetFd);
        close(iSourceFd);

        // pad with 0 to the rest of Disk.img to fit the sector size(512byte)
        iKernel32SectorCount = AdjustInSectorSize(iTargetFd, iSourceSize);
        printf("[INFO] %s size = [%d] and sector count = [%d]\n", argv[2], iSourceSize, iKernel32SectorCount);

        //-------------------------------------------------
        // update kernel information to Disk.img
        //-------------------------------------------------
        printf("[INFO] Start to write kernel information\n");
        // write kernel sector size to 5th byte of bootloader
        WriteKernelInformation(iTargetFd, iKernel32SectorCount);
        printf("[INFO] Image file create complete\n");

        close(iTargetFd);
        return 0;
}


// fill with 0x00 from current offset to multiple of 512byte(sector size)
int AdjustInSectorSize(int iFd, int iSourceSize)
{
        int i;
        int iAdjustSizeToSector;
        char cCh;
        int iSectorCount;

        iAdjustSizeToSector = iSourceSize % BYTEOFSECTOR;
        cCh = 0x00;

        if (iAdjustSizeToSector != 0)
        {
                iAdjustSizeToSector = 512 - iAdjustSizeToSector;
                printf("[INFO] File size [%lu] and fill [%u] byte\n", iSourceSize, iAdjustSizeToSector);
                for (i = 0; i < iAdjustSizeToSector; i++)
                        write(iFd, &cCh, 1);
        } else {
                printf("[INFO] File size is aligned 512 byte\n");
        }

        iSectorCount = (iSourceSize + iAdjustSizeToSector) / BYTEOFSECTOR;
        return iSectorCount;
}


// Insert kernel information into bootloader
void WriteKernelInformation(int iTargetFd, int iKernelSectorCount)
{
        unsigned short usData;
        long lPosition;

        // 5th word represents the sector count for the size of kernel image
        lPosition = lseek(iTargetFd, (off_t)5, SEEK_SET);
        if (lPosition == -1) {
                fprintf(stderr, "lseek fail. Return value = %d, errno =%d, %d\n", lPosition, errno, SEEK_SET);
                exit(-1);
        }

        usData = (unsigned short)iKernelSectorCount;
        write(iTargetFd, &usData, 2);

        printf("[INFO] Total sector count except boot loader [%d]\n", iKernelSectorCount);
}


// Copy Source FD contents to the Target FD and return the size of copy
int CopyFile(int iSourceFd, int iTargetFd)
{
        int iSourceFileSize;
        int iRead;
        int iWrite;
        char vcBuffer[BYTEOFSECTOR];

        iSourceFileSize = 0;
        while (1) {
                iRead = read(iSourceFd, vcBuffer, sizeof(vcBuffer));
                iWrite = write(iTargetFd, vcBuffer, iRead);

                if (iRead != iWrite) {
                        fprintf(stderr, "[ERROR] iRead != iWrite\n");
                        exit(-1);
                }
                iSourceFileSize += iRead;

                if (iRead != sizeof(vcBuffer))
                        break;
        }
        
        return iSourceFileSize;
}