@echo off

set qemu_path=C:\cygwin64\home\seong\mint64\qemu\

"%qemu_path%qemu-system-x86_64.exe" -L . -m 64 -fda Disk.img -M pc
