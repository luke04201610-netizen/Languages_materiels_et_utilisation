// Test bench of the processor with clock and reset (partie 4.2).
// The data are still in the internal memory of the processor:
// the bus towards the quadram is not connected yet (dataToRead = 0).
module tb_riscvproc;

  reg clock = 0;
  reg reset = 1;

  wire [11:0] address;
  wire [31:0] dataToWrite;
  wire        we;

  riscvproc cpu (
    .clock       (clock),
    .reset       (reset),
    .address     (address),
    .dataToWrite (dataToWrite),
    .dataToRead  (32'b0),
    .we          (we)
  );

  always #5 clock = ~clock;   // period 10 ns

  initial begin
    #12 reset = 0;            // reset seen by the first falling edge (10 ns)
    #100000;
    $display("Timeout: the program did not reach ebreak");
    $finish;
  end
endmodule