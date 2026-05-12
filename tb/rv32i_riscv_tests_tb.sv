// RISC-V Official Test Suite Testbench
//
// Compatible with the riscv-tests convention:
//   - Test writes result to x3 (gp register)
//   - x3 = 1 means PASS
//   - x3 != 1 means FAIL (x3 >> 1 gives the failing test number)
//   - Test signals completion by writing to address 0x100 (tohost)
//
// Usage:
//   1. Compile a test: riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 ...
//   2. Convert to hex: objcopy -O verilog test.elf test.hex
//   3. Copy as program.hex to the simulation directory
//   4. Run this testbench

`timescale 1ns / 1ps

module rv32i_riscv_tests_tb;

    logic        clk;
    logic        rst_n;
    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic [31:0] debug_alu_result;

    rv32i_pipeline_top dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .debug_pc        (debug_pc),
        .debug_instr     (debug_instr),
        .debug_alu_result(debug_alu_result)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Detect tohost write (ecall or write to special address)
    // riscv-tests convention: test ends when gp (x3) is set and
    // an ECALL instruction (0x00000073) is executed, or when the
    // program loops indefinitely.
    logic [31:0] gp_value;
    logic [31:0] prev_pc;
    int          same_pc_count;
    logic        test_done;

    assign gp_value = dut.u_regfile.regs[3];

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            prev_pc       <= 32'hFFFF;
            same_pc_count <= 0;
            test_done     <= 0;
        end else begin
            // Detect halt (PC cycling = jal x0, 0 or ecall loop)
            if (debug_pc == prev_pc ||
                (debug_pc == prev_pc + 4 && debug_instr == 32'h0000006f))
                same_pc_count <= same_pc_count + 1;
            else
                same_pc_count <= 0;
            prev_pc <= debug_pc;

            if (same_pc_count > 20 && !test_done)
                test_done <= 1;

            // Also detect ecall (instruction = 0x00000073)
            if (debug_instr == 32'h00000073 && !test_done)
                test_done <= 1;
        end
    end

    initial begin
        $display("=== RISC-V Compliance Test ===");

        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // Wait for test to complete or timeout
        fork
            begin
                wait (test_done);
            end
            begin
                repeat (10000) @(posedge clk);
            end
        join_any

        repeat (10) @(posedge clk);

        // Check result
        if (gp_value == 32'd1) begin
            $display("PASS");
        end else if (gp_value == 32'd0) begin
            $display("FAIL: gp = 0 (test did not complete)");
        end else begin
            $display("FAIL: test case %0d failed (gp = 0x%08h)", gp_value >> 1, gp_value);
        end

        // Dump register state
        $display("--- Register State ---");
        for (int i = 0; i < 32; i++) begin
            if (dut.u_regfile.regs[i] != 0)
                $display("  x%0d = 0x%08h", i, dut.u_regfile.regs[i]);
        end

        $finish;
    end

    // Hard timeout
    initial begin
        #500000;
        $display("TIMEOUT");
        $finish;
    end

endmodule
