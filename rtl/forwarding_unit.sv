// 00 = no forward, 01 = from EX/MEM, 10 = from MEM/WB
// EX/MEM has priority since it's the more recent result.

module forwarding_unit (
  input logic [4:0] ex_rs1_addr, ex_rs2_addr,
  input logic [4:0] mem_rd_addr,
  input logic mem_reg_write,
  input logic [4:0] wb_rd_addr,
  input logic wb_reg_write,
  output logic [1:0] forward_a,
  output logic [1:0] forward_b
);

  always_comb begin
    forward_a = 2'b00;
    forward_b = 2'b00;

    // forward from EX/MEM
    if (mem_reg_write && mem_rd_addr != 0 && mem_rd_addr == ex_rs1_addr)
      forward_a = 2'b01;
    if (mem_reg_write && mem_rd_addr != 0 && mem_rd_addr == ex_rs2_addr)
      forward_b = 2'b01;

    // forward from MEM/WB (only if EX/MEM isn't already forwarding)
    if (wb_reg_write && wb_rd_addr != 0 && wb_rd_addr == ex_rs1_addr
        && !(mem_reg_write && mem_rd_addr != 0 && mem_rd_addr == ex_rs1_addr))
      forward_a = 2'b10;
    if (wb_reg_write && wb_rd_addr != 0 && wb_rd_addr == ex_rs2_addr
        && !(mem_reg_write && mem_rd_addr != 0 && mem_rd_addr == ex_rs2_addr))
      forward_b = 2'b10;
  end

endmodule
