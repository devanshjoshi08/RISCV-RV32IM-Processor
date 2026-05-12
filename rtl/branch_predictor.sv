// 64-entry BHT with 2-bit saturating counters.
// indexed by PC[7:2], predict = MSB of counter.

module branch_predictor #(
  parameter BHT_DEPTH = 64,
  parameter INDEX_BITS = $clog2(BHT_DEPTH)
)(
  input logic clk, rst_n,
  input logic [31:0] pc_if,
  output logic predict_taken,
  input logic update_en,
  input logic [31:0] update_pc,
  input logic actual_taken
);

  logic [1:0] bht [0:BHT_DEPTH-1];

  logic [INDEX_BITS-1:0] predict_index;
  logic [INDEX_BITS-1:0] update_index;
  assign predict_index = pc_if[INDEX_BITS+1:2];
  assign update_index = update_pc[INDEX_BITS+1:2];

  assign predict_taken = bht[predict_index][1];

  integer i;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (i = 0; i < BHT_DEPTH; i++)
        bht[i] <= 2'b01; // weakly not taken
    end else if (update_en) begin
      if (actual_taken && bht[update_index] < 2'b11)
        bht[update_index] <= bht[update_index] + 1;
      else if (!actual_taken && bht[update_index] > 2'b00)
        bht[update_index] <= bht[update_index] - 1;
    end
  end

endmodule
