all : Bootloader Kernel32 Disk.img

Bootloader:
	@echo 
	@echo ==== build Bootloader ====
	@echo

	make -C 00.Bootloader

	@echo 
	@echo ==== Bootloader build complete ====
	@echo


Kernel32 : 
	@echo 
	@echo ==== build 32bit kernel ====
	@echo
	make -C 01.Kernel32
	@echo 
	@echo ==== 32bit kernel build complete ====
	@echo




Disk.img : 00.Bootloader/Bootloader.bin 01.Kernel32/Kernel32.bin
	@echo 
	@echo ==== Disk Image Build Start ====
	@echo

	cat  $^ > Disk.img

	@echo 
	@echo ==== Disk Image build complete ====
	@echo

clean : 
	make -C 00.Bootloader clean
	make -C 01.Kernel32 clean
	rm -f Disk.img