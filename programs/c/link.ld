/* Linker script for RV32I processor */
/* Memory map matches the MMIO controller */

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    DMEM (rwx) : ORIGIN = 0x00000000, LENGTH = 4K
}

SECTIONS
{
    .text :
    {
        *(.text.init)       /* startup code first */
        *(.text*)
    } > IMEM

    .rodata :
    {
        *(.rodata*)
    } > DMEM

    .data :
    {
        *(.data*)
    } > DMEM

    .bss :
    {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        __bss_end = .;
    } > DMEM

    /* Stack grows downward from top of DMEM */
    __stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}
