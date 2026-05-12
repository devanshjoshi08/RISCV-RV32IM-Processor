module imem #(parameter DEPTH = 1024) (
  input logic [31:0] addr,
  output logic [31:0] instr
);

  logic [31:0] mem [0:DEPTH-1];

  initial begin
    for (int i = 0; i < DEPTH; i++)
      mem[i] = 32'h00000013; // NOP

    // default program for synthesis (sum 1..10)
    mem[0] = 32'h00000093; // addi x1, x0, 0
    mem[1] = 32'h00100113; // addi x2, x0, 1
    mem[2] = 32'h00B00193; // addi x3, x0, 11
    mem[3] = 32'h002080B3; // add x1, x1, x2
    mem[4] = 32'h00110113; // addi x2, x2, 1
    mem[5] = 32'hFE314CE3; // blt x2, x3, -8
    mem[6] = 32'h00102023; // sw x1, 0(x0)
    mem[7] = 32'h00008293; // addi x5, x1, 0
    mem[8] = 32'h0000006F; // jal x0, 0 (halt)

    $readmemh("program.hex", mem);
  end

  assign instr = mem[addr[31:2]];

endmodule
