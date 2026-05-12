// stall on load-use (can't forward data that hasn't left memory yet),
// flush on branch mispredict or jump (kill the 2 wrong instructions in flight).

module hazard_unit (
  input logic ex_mem_read,
  input logic [4:0] ex_rd_addr,
  input logic [4:0] id_rs1_addr, id_rs2_addr,
  input logic branch_taken, jal_ex, jalr_ex,
  output logic pc_stall, if_id_stall, if_id_flush, id_ex_flush
);

  logic load_use;
  assign load_use = ex_mem_read && (ex_rd_addr != 0) &&
                    ((ex_rd_addr == id_rs1_addr) || (ex_rd_addr == id_rs2_addr));

  always_comb begin
    pc_stall = 0;
    if_id_stall = 0;
    if_id_flush = 0;
    id_ex_flush = 0;

    if (load_use) begin
      pc_stall = 1;
      if_id_stall = 1;
      id_ex_flush = 1;
    end

    if (branch_taken || jal_ex || jalr_ex) begin
      if_id_flush = 1;
      id_ex_flush = 1;
      pc_stall = 0;
      if_id_stall = 0;
    end
  end

endmodule
