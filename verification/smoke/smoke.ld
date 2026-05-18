ENTRY(_start)

SECTIONS
{
    . = 0x00000000;

    .text : ALIGN(4)
    {
        *(.text.start)
        *(.text*)
        *(.rodata*)
    }

    .data : ALIGN(4)
    {
        *(.data*)
    }

    .bss : ALIGN(4)
    {
        *(.bss*)
        *(COMMON)
    }

    . = 0x00000100;
    PROVIDE(tohost = .);

    . = 0x00000120;
    PROVIDE(begin_signature = .);
    PROVIDE(end_signature = .);
}
