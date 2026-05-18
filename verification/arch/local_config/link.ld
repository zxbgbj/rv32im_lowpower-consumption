OUTPUT_ARCH("riscv")
ENTRY(rvtest_entry_point)

SECTIONS
{
    . = 0x00000000;

    .text.init : ALIGN(4)
    {
        *(.text.init)
    }

    .text.rvtest : ALIGN(4)
    {
        *(.text.rvtest)
        *(.text.rvtest.*)
    }

    .text : ALIGN(4)
    {
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    }

    .text.rvmodel : ALIGN(4)
    {
        *(.text.rvmodel)
        *(.text.rvmodel.*)
    }

    . = 0x0006F000;
    .tohost : ALIGN(8)
    {
        *(.tohost)
    }

    . = 0x00070000;
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

    . = ALIGN(4);
    _end = .;
}
