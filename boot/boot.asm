
; ***************************************************************************************
;
;                               boot.asm
; 
;                                                     SunMs, 2016.10
; ***************************************************************************************


;%define	_BOOT_DEBUG_	; Just be used in debug mode as an .com file. via nasm Boot.asm -o Boot.com

%ifdef	_BOOT_DEBUG_
	org  0100h				; Debug Mode, as an n.COM file
%else
	org  07c00h				; Normal Mode, BIOS loads Boot Sector into 0:7C00
%endif

;================================================================================================
%ifdef	_BOOT_DEBUG_
BaseOfStack	equ	0100h		; Debug Mode. the bottom of Stack, growing from this base to low address.
%else
BaseOfStack	equ	07c00h		; Normal Mode. the bottom of Stack, growing from this base to low address.
%endif

%include	"load.inc"
;================================================================================================

	jmp short LABEL_START	; Start to boot.
	nop						; Necessary.

;Include the FAT12 header.
%include	"fat12hdr.inc"

LABEL_START:	
	mov	ax, cs
	mov	ds, ax
	mov	es, ax
	mov	ss, ax
	mov	sp, BaseOfStack

	;Clear the screen
	mov	ax, 0600h			; AH = 6,  AL = 0h
	mov	bx, 0700h			; Black Background, White Front(BL = 07h)
	mov	cx, 0				; Pos of Left-Up(0, 0)
	mov	dx, 0184fh			; Pos of Right-Down(80, 50)
	int	10h					; int 10h

	mov	dh, 0				; "Booting  "
	call	DispStr			; Display the string.
	
	;Reset the floppy driver.
	xor	ah, ah
	xor	dl, dl
	int	13h
	
;Find LOADER.BIN in Root Directoty of A: Disk.
	mov	word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:
	cmp	word [wRootDirSizeForLoop], 0	; 14 sectors
	jz	LABEL_NO_LOADERBIN				; Check if reading the root folder is finished ?
	dec	word [wRootDirSizeForLoop]		; If Yes, not found LOADER.BIN
	mov	ax, BaseOfLoader
	mov	es, ax							; es <= BaseOfLoader
	mov	bx, OffsetOfLoader				; bx <= OffsetOfLoader, Then es:bx = BaseOfLoader:OffsetOfLoader
	mov	ax, [wSectorNo]					; ax <= Sector No. in Root Directory
	mov	cl, 1
	call	ReadSector

	mov	si, LoaderFileName				; ds:si => "LOADER  BIN"
	mov	di, OffsetOfLoader				; es:di => BaseOfLoader:0100 = BaseOfLoader*10h + 100
	cld
	mov	dx, 10h							; 512 / 0x20 = 16, number of Root Directory Entry
LABEL_SEARCH_FOR_LOADERBIN:
	cmp	dx, 0								; Check the loop conter
	jz	LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR	; If finishing reading one sector
	dec	dx									; Go to next sector.
	mov	cx, 11								; Charactor Number of file name.
LABEL_CMP_FILENAME:
	cmp	cx, 0
	jz	LABEL_FILENAME_FOUND		; If all the 11 chars are matched, find it.
	dec	cx
	lodsb							; ds:si => al
	cmp	al, byte [es:di]
	jz	LABEL_GO_ON
	jmp	LABEL_DIFFERENT				; Any one char is not right, pass the current Directory Entry.
;LOADER.BIN we are finding.
LABEL_GO_ON:
	inc	di
	jmp	LABEL_CMP_FILENAME			; Go on comparing.

LABEL_DIFFERENT:
	and	di, 0FFE0h					; di &= E0h, point at the start of this Entry.
	add	di, 20h						; di += 20h, go to next Entry.
	mov	si, LoaderFileName	
	jmp	LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
	add	word [wSectorNo], 1
	jmp	LABEL_SEARCH_IN_ROOT_DIR_BEGIN

LABEL_NO_LOADERBIN:
	mov	dh, 2				; "No LOADER."
	call	DispStr			; Display the string
%ifdef	_BOOT_DEBUG_
	mov	ax, 4c00h
	int	21h					; Not found LOADER.BIN, go to dos
%else
	jmp	$					; Not found LOADER.BIN, dead loop here.
%endif

LABEL_FILENAME_FOUND:			; Found LOADER.BIN!!!
	mov	ax, RootDirSectors
	and	di, 0FFE0h				; di => The start of cuttent Entry
	add	di, 01Ah				; di => First Sector.
	mov	cx, word [es:di]
	push	cx					; Save the No of the sector in FAT
	add	cx, ax
	add	cx, DeltaSectorNo		; Here the Start Sector No(counted from 0) of LOADER.BIN saved in CL.
	mov	ax, BaseOfLoader
	mov	es, ax					; es <= BaseOfLoader
	mov	bx, OffsetOfLoader		; bx <= OffsetOfLoader then es:bx = BaseOfLoader:OffsetOfLoader = BaseOfLoader * 10h + OffsetOfLoader
	mov	ax, cx					; ax <= Sector No.

LABEL_GOON_LOADING_FILE:
	push	ax			; Every reading one sector will print a '.' after "Booting " like below:
	push	bx			; 
	mov	ah, 0Eh			; 
	mov	al, '.'			; Booting ......
	mov	bl, 0Fh			; 
	int	10h				;
	pop	bx				;
	pop	ax				;

	mov	cl, 1
	call	ReadSector
	pop	ax					; Get the No. of this sector in FAT.
	call	GetFATEntry
	cmp	ax, 0FFFh
	jz	LABEL_FILE_LOADED
	push	ax				; Save the No. of this sector in FAT. 
	mov	dx, RootDirSectors
	add	ax, dx
	add	ax, DeltaSectorNo
	add	bx, [BPB_BytsPerSec]
	jmp	LABEL_GOON_LOADING_FILE
LABEL_FILE_LOADED:

	mov	dh, 1				; "Ready."
	call	DispStr			; Display the string.

; *****************************************************************************************************
	jmp	BaseOfLoader:OffsetOfLoader	; This statement means jumping into the start 
									; of LOADER.BIN and Execute the code of LOADER.BIN
									; The task of "Boot Sector" is finished!
; *****************************************************************************************************



;============================================================================
;Global Variables
;----------------------------------------------------------------------------
wRootDirSizeForLoop	dw	RootDirSectors	; The No. of sectors LOADER.BIN populate.
wSectorNo		dw	0					; The No. of sector to be read.
bOdd			db	0					; Flag to indicate odd or even

;============================================================================
;Constant Strings
;----------------------------------------------------------------------------
LoaderFileName		db	"LOADER  BIN", 0	; The string of LOADER.BIN file name.
;To simplify the code, the length of the strings below all are the same as MessageLength.
MessageLength		equ	9
BootMessage:		db	"Booting  "; 9 Bytes, with space if not sufficiant, No.0
Message1			db	"Ready.   "; 9 Bytes, with space if not sufficiant, No.1
Message2			db	"No LOADER"; 9 Bytes, with space if not sufficiant, No.2
;============================================================================


;----------------------------------------------------------------------------
; Function: DispStr
;----------------------------------------------------------------------------
; Description:
; 	Reading "cl" sectors into es:bx from Sector "ax".
DispStr:
	mov	ax, MessageLength
	mul	dh
	add	ax, BootMessage
	mov	bp, ax				; ES:BP = The address of the string.
	mov	ax, ds				; 
	mov	es, ax				;	 
	mov	cx, MessageLength	; CX = The length of the string.
	mov	ax, 01301h			; AH = 13,  AL = 01h
	mov	bx, 0007h			; Page No. = 0(BH = 0), Black Background and White Fonts(BL = 07h)
	mov	dl, 0
	int	10h					; int 10h
	ret


;----------------------------------------------------------------------------
; Funtion: ReadSector
;----------------------------------------------------------------------------
; Description:
;	TBD
ReadSector:
	; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1
	push	bp
	mov	bp, sp
	sub	esp, 2			; 辟出两个字节的堆栈区域保存要读的扇区数: byte [bp-2]

	mov	byte [bp-2], cl
	push	bx			; 保存 bx
	mov	bl, [BPB_SecPerTrk]	; bl: 除数
	div	bl			; y 在 al 中, z 在 ah 中
	inc	ah			; z ++
	mov	cl, ah			; cl <- 起始扇区号
	mov	dh, al			; dh <- y
	shr	al, 1			; y >> 1 (其实是 y/BPB_NumHeads, 这里BPB_NumHeads=2)
	mov	ch, al			; ch <- 柱面号
	and	dh, 1			; dh & 1 = 磁头号
	pop	bx			; 恢复 bx
	; 至此, "柱面号, 起始扇区, 磁头号" 全部得到 ^^^^^^^^^^^^^^^^^^^^^^^^
	mov	dl, [BS_DrvNum]		; 驱动器号 (0 表示 A 盘)
.GoOnReading:
	mov	ah, 2			; 读
	mov	al, byte [bp-2]		; 读 al 个扇区
	int	13h
	jc	.GoOnReading		; 如果读取错误 CF 会被置为 1, 这时就不停地读, 直到正确为止

	add	esp, 2
	pop	bp

	ret

;----------------------------------------------------------------------------
; 函数名: GetFATEntry
;----------------------------------------------------------------------------
; 作用:
;	找到序号为 ax 的 Sector 在 FAT 中的条目, 结果放在 ax 中
;	需要注意的是, 中间需要读 FAT 的扇区到 es:bx 处, 所以函数一开始保存了 es 和 bx
GetFATEntry:
	push	es
	push	bx
	push	ax
	mov	ax, BaseOfLoader	; ┓
	sub	ax, 0100h			; ┣ 在 BaseOfLoader 后面留出 4K 空间用于存放 FAT
	mov	es, ax				; ┛
	pop	ax
	mov	byte [bOdd], 0
	mov	bx, 3
	mul	bx			; dx:ax = ax * 3
	mov	bx, 2
	div	bx			; dx:ax / 2  ==>  ax <- 商, dx <- 余数
	cmp	dx, 0
	jz	LABEL_EVEN
	mov	byte [bOdd], 1
LABEL_EVEN:;偶数
	xor	dx, dx			; 现在 ax 中是 FATEntry 在 FAT 中的偏移量. 下面来计算 FATEntry 在哪个扇区中(FAT占用不止一个扇区)
	mov	bx, [BPB_BytsPerSec]
	div	bx			; dx:ax / BPB_BytsPerSec  ==>	ax <- 商   (FATEntry 所在的扇区相对于 FAT 来说的扇区号)
					;				dx <- 余数 (FATEntry 在扇区内的偏移)。
	push	dx
	mov	bx, 0			; bx <- 0	于是, es:bx = (BaseOfLoader - 100):00 = (BaseOfLoader - 100) * 10h
	add	ax, SectorNoOfFAT1	; 此句执行之后的 ax 就是 FATEntry 所在的扇区号
	mov	cl, 2
	call	ReadSector		; 读取 FATEntry 所在的扇区, 一次读两个, 避免在边界发生错误, 因为一个 FATEntry 可能跨越两个扇区
	pop	dx
	add	bx, dx
	mov	ax, [es:bx]
	cmp	byte [bOdd], 1
	jnz	LABEL_EVEN_2
	shr	ax, 4
LABEL_EVEN_2:
	and	ax, 0FFFh

LABEL_GET_FAT_ENRY_OK:

	pop	bx
	pop	es
	ret
;----------------------------------------------------------------------------

times 	510-($-$$)	db	0	; 填充剩下的空间，使生成的二进制代码恰好为512字节
dw 	0xaa55					; 结束标志
