@echo off

set qemu_path=C:\qemu\

"%qemu_path%qemu-system-x86_64.exe" -L . -m 64 -fda Disk.img -M pc