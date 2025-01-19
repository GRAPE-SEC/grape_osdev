@echo off
set qemu_path=C:\Youngjun\mint64os\qemu-0.10.4\

%qemu_path%qemu-system-x86_64.exe -L %qemu_path% -m 64 -fda Disk.img -M pc