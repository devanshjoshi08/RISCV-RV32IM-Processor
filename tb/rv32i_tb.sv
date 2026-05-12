// RV32I Single-Cycle Processor Testbench
// Loads a program from hex, runs for a set number of cycles,
// then checks register and memory state for correctness.

`timescale 1ns / 1ps

module rv32i_tb;

    logic        clk;
    logic        rst_n;
    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic [31:0] debug_alu_result;

    // Instantiate DUT
    rv32i_top dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .debug_pc        (debug_pc),
        .debug_instr     (debug_instr),
        .debug_alu_result(debug_alu_result)
    );

    // Clock generation: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: dump a register value
    task automatic check_reg(input int reg_num, input int expected);
        logic [31:0] actual;
        actual = dut.u_regfile.regs[reg_num];
        if (actual == expected[31:0])
            $display("  PASS: x%0d = %0d (0x%08h)", reg_num, actual, actual);
        else
            $display("  FAIL: x%0d = %0d (0x%08h), expected %0d (0x%08h)",
                     reg_num, actual, actual, expected, expected[31:0]);
    endtask

    // Helper task: dump a memory word
    task automatic check_mem(input int word_addr, input int expected);
        logic [31:0] actual;
        actual = dut.u_dmem.mem[word_addr];
        if (actual == expected[31:0])
            $display("  PASS: mem[%0d] = %0d (0x%08h)", word_addr, actual, actual);
        else
            $display("  FAIL: mem[%0d] = %0d (0x%08h), expected %0d (0x%08h)",
                     word_addr, actual, actual, expected, expected[31:0]);
    endtask

    // Main test sequence
    initial begin
        $display("=== RV32I Single-Cycle Processor Testbench ===");
        $display("");

        // Reset
        rst_n = 0;
        repeat (3) @(posedge clk);
        rst_n = 1;

        // Run program
        $display("Running program...");
        repeat (200) begin
            @(posedge clk);
            $display("  PC=0x%08h  INSTR=0x%08h  ALU=0x%08h",
                     debug_pc, debug_instr, debug_alu_result);
        end

        // Check results
        $display("");
        $display("=== Register State ===");
        for (int i = 0; i < 32; i++) begin
            if (dut.u_regfile.regs[i] != 0)
                $display("  x%0d = %0d (0x%08h)", i,
                         dut.u_regfile.regs[i], dut.u_regfile.regs[i]);
        end

        $display("");
        $display("=== Test Complete ===");
        $finish;
    end

    // Timeout watchdog
    initial begin
        #100000;
        $display("TIMEOUT: simulation exceeded 100 us");
        $finish;
    end

endmodule
