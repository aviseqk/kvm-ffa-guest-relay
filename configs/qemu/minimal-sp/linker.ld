ENTRY(_start)

SECTIONS
{
    . = 0x0;

    .text : ALIGN(16)
    {
        KEEP(*(.text._start))
        KEEP(*(.text))
        KEEP(*(.text.*))
    }

    .rodata : ALIGN(16)
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data : ALIGN(16)
    {
        *(.data)
        *(.data.*)
    }

    .bss : ALIGN(16)
    {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        __bss_end = .;
    }

    /* Simple 16 KiB stack for the first execution context. */
    . = ALIGN(16);

    . += 0x4000;

    __stack_top = .;

    . = ALIGN(4096);
    __image_end = .;

    /DISCARD/ :
    {
        *(.comment)
        *(.note*)
        *(.eh_frame*)
        *(.gcc_except_table*)
    }
}
