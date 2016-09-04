# Declare constants for the multiboot header.
.set ALIGN,    1<<0             # align loaded modules on page boundaries
.set MEMINFO,  1<<1             # provide memory map
.set FLAGS,    ALIGN | MEMINFO  # this is the Multiboot 'flag' field
.set MAGIC,    0x1BADB002       # 'magic number' lets bootloader find the header
.set CHECKSUM, -(MAGIC + FLAGS) # checksum of above, to prove we are multiboot

# Declare a multiboot header that marks the program as a kernel. These are magic
# values that are documented in the multiboot standard. The bootloader will
# search for this signature in the first 8 KiB of the kernel file, aligned at a
# 32-bit boundary. The signature is in its own section so the header can be
# forced to be within the first 8 KiB of the kernel file.
.section .multiboot
.align 4
.long MAGIC
.long FLAGS
.long CHECKSUM

# Set up stack to be 16kB large and define boundaries.
.section .bss
.align 16
stack_bottom:
.skip 16384  #16 kB
stack_top:

# Linker will jump to this section as its entry (as defined in linker.ld)
.section .text
.global _start
.type _start, @function
_start:
	# The bootloader loads into 32-bit protected mode with
	# interrupts disabled, paging disabled, and the processor state
	# being defaulted to what is in the multiboot standard.

	# Make sure interrupts are off before initializing things
	cli
	jmp continue

continue:
	# Load GDT - Global Descriptor Table - defined in x86_desc.S
	lgdt gdt_desc_ptr

	# Load the IDT
	push %eax
	push %edx
	push %ecx

	call init_interrupts

	pop %ecx
	pop %edx
	pop %eax


	# Move ESP to top of stack (grows downwards on x86 systems).
	mov $stack_top, %esp


	# TODO: Initialize processor state here

	# Enter the main kernel function
	call kernel_main

	#Should not reach here, but if so, spin infinitely
	cli
1:	hlt
	jmp 1b

