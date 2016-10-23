# toy_os

It will be a little os which is mainly used to study the principle of os.

I will push codes and related files(like image, configured files) into Git repo too.


1. Used tools/softwares:
  1.1 VMware 12.5
  1.2 Ubuntu-12.04.5
  1.3 Bochs-2.2.1
  1.4 NASM-2.10.5（under Linux)
  1.5 GCC（within Ubuntu）
  
2. Steps:
  2.1 Compile the source file:
     nasm xxx.asm -o xxx.com
  2.2 Mount onto the floppy and copy the binary file:
     sudo mount -o loop xxx.img /mnt/hgfs/xxx/xxx/...(where yout share folder located)
	 sudo cp xxx.com /mnt/hgfs/xxx/xxx/...
	 sudo umount /mnt/hgfs/xxx/xxx/...
  2.3 Run the program:
     a) double click the configuration file bochsrc.bxrc
	 b) when you see the dos window, run B:\xxx.com
  2.4 Debug the program:
	 a) skip the step 2.3
	 b) run the debug.bat in Windows
	 c) debug with the command in cmd.exe window...
	 