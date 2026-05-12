# sum_1_to_10.s
# Sums integers 1 through 10, stores result (55) in x5 and memory[0].
# This is the Phase 1/2 validation program.
#
# Expected result: x1 = 55, x5 = 55, mem[0] = 55

        addi x1, x0, 0         # x1 = sum = 0
        addi x2, x0, 1         # x2 = i = 1
        addi x3, x0, 11        # x3 = limit = 11 (exclusive upper bound)
loop:
        add  x1, x1, x2        # sum += i
        addi x2, x2, 1         # i++
        blt  x2, x3, loop      # if i < 11, branch back to loop
        sw   x1, 0(x0)         # store sum to mem[0]
        addi x5, x1, 0         # copy sum to x5 for observation
end:
        jal  x0, end            # infinite loop (halt)
