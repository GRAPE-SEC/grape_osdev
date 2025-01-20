all : Bootloader Disk.img Kernel32

Bootloader:
	@echo 
	@echo ==== build Bootloader ====
	@echo

	make -C 00.Bootloader

	@echo 
	@echo ==== build complete ====
	@echo


Kernel32 : 
	@echo 
	@echo ==== build 32bit kernel ====
	@echo
		make -C 01.Kernel32
	@echo 
	@echo ==== 32bit kernel build complete ====
	@echo




Disk.img : Bootloader Kernel32
	@echo 
	@echo ==== Disk Image Build Start ====
	@echo

	cat 00.Bootloader/Bootloader.bin 01.Kernel32/VirtualOS.bin > Disk.img

	@echo 
	@echo ==== build complete ====
	@echo

clean : 
	make -C 00.Bootloader clean
	make -C 01.Kernel32 clean
	rm -f Disk.img