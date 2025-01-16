all : Bootloader Disk.img

Bootloader:
	@echo 
	@echo ==== build Bootloader ====
	@echo

	make -C 00.Bootloader

	@echo 
	@echo ==== build complete ====
	@echo


Disk.img : 00.Bootloader/Bootloader.bin
	@echo 
	@echo ==== Disk Image Build Start ====
	@echo

	cp 00.Bootloader/Bootloader.bin Disk.img

	@echo 
	@echo ==== build complete ====
	@echo

clean : 
	make -C 00.Bootloader clean
	rm -f Disk.img