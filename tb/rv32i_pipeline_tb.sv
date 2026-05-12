// RV32I Pipelined Processor Testbench
// Runs the sum_1_to_10 program and verifies x1 = x5 = 55, mem[0] = 55.
// Accounts for pipeline latency (more cycles needed than single-cycle).

`timescale 1ns / 1ps

module rv32i_pipeline_tb;

    logic        clk;
    logic        rst_n;
    logic [31:0] debug_pc;
    logic [31:0] debug_instr;
    logic [31:0] debug_alu_result;

    // Instantiate pipelined DUT
    rv32i_pipeline_top dut (
        .clk             (clk),
        .rst_n           (rst_n),
        .debug_pc        (debug_pc),
        .debug_instr     (debug_instr),
        .debug_alu_result(debug_alu_result)
    );

    // Clock: 10 ns period (100 MHz)
    initial clk = 0;
    always #5 clk = ~clk;

    // Detect halt: jal x0, 0 causes PC to cycle through 3 values due to
    // the pipeline (fetch, flush, re-fetch). Track if the same PC appears
    // repeatedly within a sliding window.
    logic [31:0] pc_history [0:3];
    int halt_count;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            halt_count <= 0;
            pc_history[0] <= 32'hFFFF;
            pc_history[1] <= 32'hFFFE;
            pc_history[2] <= 32'hFFFD;
            pc_history[3] <= 32'hFFFC;
        end else begin
            pc_history[3] <= pc_history[2];
            pc_history[2] <= pc_history[1];
            pc_history[1] <= pc_history[0];
            pc_history[0] <= debug_pc;
            // Detect if current PC matches the PC from 3 cycles ago (loop period)
            if (debug_pc == pc_history[2] || debug_pc == pc_history[3])
                halt_count <= halt_count + 1;
            else
                halt_count <= 0;
        end
    end

    // Helper tasks
    task automatic check_reg(input int reg_num, input int expected);
        logic [31:0] actual;
        actual = dut.u_regfile.regs[reg_num];
        if (actual == expected[31:0])
            $display("  PASS: x%0d = %0d (0x%08h)", reg_num, actual, actual);
        else
            $display("  FAIL: x%0d = %0d (0x%08h), expected %0d (0x%08h)",
                     reg_num, actual, actual, expected, expected[31:0]);
    endtask

    task automatic check_mem(input int word_addr, input int expected);
        logic [31:0] actual;
        actual = dut.u_dmem.mem[word_addr];
        if (actual == expected[31:0])
            $display("  PASS: mem[%0d] = %0d (0x%08h)", word_addr, actual, actual);
        else
            $display("  FAIL: mem[%0d] = %0d (0x%08h), expected %0d (0x%08h)",
                     word_addr, actual, actual, expected, expected[31:0]);
    endtask

    // Main test
    initial begin
        $display("=== RV32I 5-Stage Pipelined Processor Testbench ===");
        $display("");

        // Reset
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;

        // Wait for program to halt (PC stops changing)
        $display("Running program...");
        fork
            begin
                // Wait until halt detected (PC stuck for 10+ cycles)
                wait (halt_count > 10);
            end
            begin
                // Timeout after 500 cycles
                repeat (500) @(posedge clk);
            end
        join_any

        // Let pipeline drain
        repeat (5) @(posedge clk);

        // Print cycle count
        $display("  Program halted at PC = 0x%08h", debug_pc);
        $display("");

        // Check expected results
        $display("=== Verification ===");
        check_reg(1, 55);       // x1 = sum = 55
        check_reg(2, 11);       // x2 = i = 11 (loop exit value)
        check_reg(3, 11);       // x3 = limit = 11
        check_reg(5, 55);       // x5 = copy of sum
        check_mem(0, 55);       // mem[0] = 55
        $display("");

        // Dump all non-zero registers
        $display("=== Full Register State ===");
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
        #200000;
        $display("TIMEOUT: simulation exceeded 200 us");
        $finish;
    end

endmodule
