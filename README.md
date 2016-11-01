# toy_os
========
It will be a little os which is mainly used to study the principle of os.

I will push codes and related files(like image, configured files) into Git repo too.

### Used tools/softwares:
- VMware 12.5
- Ubuntu-12.04.5
- Bochs-2.2.1
- NASM-2.10.5 (under Linux)
- GCC (within Ubuntu)
    
### Steps:
- Compile the source file:

		$ nasm xxx.asm -o xxx.com
	
- Mount onto the floppy and copy the binary file:

		$ sudo mount -o loop xxx.img /mnt/hgfs/xxx/xxx/...(where your share folder located)
	
		$ sudo cp xxx.com /mnt/hgfs/xxx/xxx/...
	
		$ sudo umount /mnt/hgfs/xxx/xxx/...
	
- Run the program:

	* double click the configuration file bochsrc.bxrc
	
	* when you see the dos window, run B:\xxx.com
	
- Debug the program:

	* skip the step 2.3
	
	* run the debug.bat in Windows
	
	* debug with the command in cmd.exe window...
	
	* Tip: put "xchg  bx, bx" before some statement and "magic_break: enabled=1" in the end of bochsrc.bxrc file. The program will stop here when debug is ruuning. But you can not run the program directly.
