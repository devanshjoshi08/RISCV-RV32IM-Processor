#!/bin/bash
# Run official RISC-V compliance tests against the processor.
#
# Prerequisites:
#   1. Clone riscv-tests: git clone https://github.com/riscv-software-src/riscv-tests
#   2. Install riscv32 GCC toolchain
#   3. Install Vivado (for xvlog/xelab/xsim) or Icarus Verilog
#
# Usage:
#   ./run_riscv_tests.sh <path-to-riscv-tests>
#
# This script compiles each RV32I test, converts it to hex, and
# runs it through the pipelined processor testbench.

TESTS_DIR=${1:-"./riscv-tests"}
RTL_DIR="$(dirname "$0")/../rtl"
TB_DIR="$(dirname "$0")/../tb"

# RV32I tests to run (from riscv-tests/isa/)
TESTS=(
    rv32ui-p-add
    rv32ui-p-addi
    rv32ui-p-and
    rv32ui-p-andi
    rv32ui-p-auipc
    rv32ui-p-beq
    rv32ui-p-bge
    rv32ui-p-bgeu
    rv32ui-p-blt
    rv32ui-p-bltu
    rv32ui-p-bne
    rv32ui-p-jal
    rv32ui-p-jalr
    rv32ui-p-lb
    rv32ui-p-lbu
    rv32ui-p-lh
    rv32ui-p-lhu
    rv32ui-p-lui
    rv32ui-p-lw
    rv32ui-p-or
    rv32ui-p-ori
    rv32ui-p-sb
    rv32ui-p-sh
    rv32ui-p-sll
    rv32ui-p-slli
    rv32ui-p-slt
    rv32ui-p-slti
    rv32ui-p-sltiu
    rv32ui-p-sltu
    rv32ui-p-sra
    rv32ui-p-srai
    rv32ui-p-srl
    rv32ui-p-srli
    rv32ui-p-sub
    rv32ui-p-sw
    rv32ui-p-xor
    rv32ui-p-xori
)

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=${#TESTS[@]}

echo "========================================"
echo "RISC-V RV32I Compliance Test Suite"
echo "Running $TOTAL tests"
echo "========================================"

for test in "${TESTS[@]}"; do
    # Check if precompiled test binary exists
    TEST_BIN="$TESTS_DIR/isa/$test"
    if [ ! -f "$TEST_BIN" ]; then
        echo "  SKIP: $test (binary not found)"
        continue
    fi

    # Convert to hex
    riscv32-unknown-elf-objcopy -O verilog "$TEST_BIN" program.hex 2>/dev/null

    # Run simulation (using Icarus Verilog for speed)
    iverilog -g2012 -o sim_test \
        "$RTL_DIR/pkg_riscv.sv" \
        "$RTL_DIR/pc.sv" \
        "$RTL_DIR/imem.sv" \
        "$RTL_DIR/regfile.sv" \
        "$RTL_DIR/alu.sv" \
        "$RTL_DIR/imm_gen.sv" \
        "$RTL_DIR/control.sv" \
        "$RTL_DIR/branch_unit.sv" \
        "$RTL_DIR/dmem.sv" \
        "$RTL_DIR/branch_predictor.sv" \
        "$RTL_DIR/icache.sv" \
        "$RTL_DIR/pipe_if_id.sv" \
        "$RTL_DIR/pipe_id_ex.sv" \
        "$RTL_DIR/pipe_ex_mem.sv" \
        "$RTL_DIR/pipe_mem_wb.sv" \
        "$RTL_DIR/forwarding_unit.sv" \
        "$RTL_DIR/hazard_unit.sv" \
        "$RTL_DIR/rv32i_pipeline_top.sv" \
        "$TB_DIR/rv32i_riscv_tests_tb.sv" 2>/dev/null

    result=$(timeout 10 vvp sim_test 2>/dev/null | grep -E "^(PASS|FAIL|TIMEOUT)")

    if echo "$result" | grep -q "PASS"; then
        echo "  PASS: $test"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  FAIL: $test  ($result)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    rm -f sim_test program.hex
done

echo "========================================"
echo "Results: $PASS_COUNT / $TOTAL passed, $FAIL_COUNT failed"
echo "========================================"
