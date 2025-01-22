all: BootLoader Disk.img

BootLoader:
	@echo =============== Build Boot Loader ===============
	make -C 00.BootLoader
	@echo =============== Build Complete ===============

Disk.img: 00.BootLoader/BootLoader.bin
	@echo =============== Disk Image Build Start ===============
	cp 00.BootLoader/BootLoader.bin Disk.img
	@echo =============== All Build Complete ===============

clean: 
	make -C 00.BootLoader clean
	rm -f Disk.img