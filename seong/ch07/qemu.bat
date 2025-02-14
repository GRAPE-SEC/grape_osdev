@echo off

set qemu_path=C:\Users\seong\Downloads\113BF3354EA8233D2B\

"%qemu_path%qemu-system-x86_64.exe" -L %qemu_path% -m 64 -fda Disk.img -M pc