OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
    . = 0x00000000;

    .text.init : ALIGN(4)
    {
        *(.text.init)
    }

    .text : ALIGN(4)
    {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    }

    . = 0x00000800;
    .tohost : ALIGN(8)
    {
        *(.tohost)
    }

    . = 0x00000900;
    .data : ALIGN(4)
    {
        *(.data)
        *(.data.*)
        *(.sdata)
        *(.sdata.*)
    }

    .bss : ALIGN(4)
    {
        *(.bss)
        *(.bss.*)
        *(COMMON)
    }

    _end = .;
}
