OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
    . = 0x00000000;

    .text.init : ALIGN(4)
    {
        KEEP(*(.text.init))
        KEEP(*(.text.start))
        KEEP(*(.init))
    }

    .text : ALIGN(4)
    {
        *(.text)
        *(.text.*)
    }

    . = 0x00004000;
    .tohost : ALIGN(8)
    {
        KEEP(*(.tohost))
        KEEP(*(.tohost.*))
    }

    .fromhost : ALIGN(8)
    {
        KEEP(*(.fromhost))
        KEEP(*(.fromhost.*))
    }

    . = 0x00004100;
    .signature : ALIGN(16)
    {
        begin_signature = .;
        KEEP(*(.signature))
        KEEP(*(.signature.*))
        end_signature = .;
    }

    . = 0x00004200;
    .rodata : ALIGN(16)
    {
        *(.rodata)
        *(.rodata.*)
        *(.srodata)
        *(.srodata.*)
    }

    .data : ALIGN(16)
    {
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
    }

    .bss (NOLOAD) : ALIGN(16)
    {
        __bss_start = .;
        *(.sbss)
        *(.sbss.*)
        *(.bss)
        *(.bss.*)
        *(COMMON)
        __bss_end = .;
    }

    . = ALIGN(16);
    __heap_start = .;

    . = 0x00007ff0;
    __stack_top = .;
    _end = .;
}
