/*
 Description: synthesizable version of the processor of part 5 (RV32I subset + RV32M)
              for the Cyclone IV E EP4CE10F17C8.

 Same instructions and same bus towards the quadram as exo/p5/riscvproc.sv, but:
  - one always block on the rising edge, written as a state machine
    (the simulation model waited for several falling edges in one block,
    which cannot be synthesized);
  - the program memory is a ROM initialised from PROG_FILE;
  - ebreak stops the processor (halted = 1) instead of calling $finish;
  - an unknown instruction is skipped and sets 'illegal' instead of $display.

 One state per clock period:
  FETCH : the ROM reads the instruction at pc
  EXEC  : the instruction is executed; for sw, address, data and we are on the bus
          and the quadram writes at the end of the period
  MEM   : lw only; the quadram has registered the address at the end of EXEC,
          dataToRead is valid and is copied into rd
*/

module riscvproc_fpga #(
  parameter PROG_FILE = "test_memoire.txt",  // program loaded into the ROM
  parameter ROM_AW    = 8                    // ROM of 2**ROM_AW instructions
) (
  input         clock,
  input         reset,        // synchronous reset, active high
  output [11:0] address,      // bus towards the quadram (word address)
  output [31:0] dataToWrite,
  input  [31:0] dataToRead,
  output        we,
  input  [4:0]  dbg_sel,      // register shown on the board
  output [31:0] dbg_reg,
  output        halted,       // ebreak reached
  output reg    illegal       // an unknown instruction has been skipped
);

  localparam [1:0] FETCH = 2'd0, EXEC = 2'd1, MEM = 2'd2, HALT = 2'd3;

  /* Opcodes */
  localparam [6:0] ARITHMETIC     = 7'b0110011,
                   IMM_ARITHMETIC = 7'b0010011,
                   LOAD           = 7'b0000011,
                   STORE          = 7'b0100011,
                   EBREAK         = 7'b1110011;

  reg [1:0]  state;
  reg [11:0] pc;
  reg [31:0] instr;                     // instruction read from the ROM
  reg [31:0] regs [0:31];               // regfile
  reg [31:0] rom  [0:(1<<ROM_AW)-1];    // program memory

  initial $readmemh(PROG_FILE, rom);

  // synchronous read: the instruction at pc is valid one period later
  always @(posedge clock)
    instr <= rom[pc[ROM_AW-1:0]];

  /* Instruction fields */
  wire [6:0]  opcode = instr[6:0];
  wire [2:0]  f3     = instr[14:12];
  wire [6:0]  f7     = instr[31:25];
  wire [4:0]  rd     = instr[11:7];
  wire [31:0] a      = regs[instr[19:15]];   // rs1
  wire [31:0] b      = regs[instr[24:20]];   // rs2
  wire [31:0] i_imm  = {{20{instr[31]}}, instr[31:20]};
  wire [31:0] s_imm  = {{20{instr[31]}}, instr[31:25], instr[11:7]};

  /* RV32M multiplier: one signed 33 x 33 product for MUL, MULH, MULHSU and MULHU */
  wire               a_signed = (f3 == 3'b001) || (f3 == 3'b010);  // MULH, MULHSU
  wire               b_signed = (f3 == 3'b001);                    // MULH
  wire signed [32:0] ma       = {a_signed & a[31], a};
  wire signed [32:0] mb       = {b_signed & b[31], b};
  wire signed [65:0] prod     = ma * mb;

  /* RV32M divider: one unsigned divider on the magnitudes, signs restored after.
     Division by 0 gives -1 and the dividend, and -2^31 / -1 gives -2^31 and 0,
     as required by the spec. */
  wire        div_signed = (f3 == 3'b100) || (f3 == 3'b110);       // DIV, REM
  wire        neg_a      = div_signed & a[31];
  wire        neg_b      = div_signed & b[31];
  wire [31:0] ua         = neg_a ? -a : a;
  wire [31:0] ub         = neg_b ? -b : b;
  wire [31:0] uq         = ua / ub;
  wire [31:0] ur         = ua % ub;
  wire [31:0] quot       = (b == 0) ? 32'hFFFFFFFF : ((neg_a ^ neg_b) ? -uq : uq);
  wire [31:0] remd       = (b == 0) ? a : (neg_a ? -ur : ur);

  /* Register-register operations: {funct3, funct7} */
  reg [31:0] r_result;
  reg        r_valid;
  always @* begin
    r_valid = 1'b1;
    case ({f3, f7})
      {3'b000, 7'b0000000}: r_result = a + b;                // ADD
      {3'b000, 7'b0100000}: r_result = a - b;                // SUB
      {3'b001, 7'b0000000}: r_result = a << b[4:0];          // SLL
      {3'b101, 7'b0000000}: r_result = a >> b[4:0];          // SRL
      {3'b000, 7'b0000001}: r_result = prod[31:0];           // MUL
      {3'b001, 7'b0000001},                                  // MULH
      {3'b010, 7'b0000001},                                  // MULHSU
      {3'b011, 7'b0000001}: r_result = prod[63:32];          // MULHU
      {3'b100, 7'b0000001},                                  // DIV
      {3'b101, 7'b0000001}: r_result = quot;                 // DIVU
      {3'b110, 7'b0000001},                                  // REM
      {3'b111, 7'b0000001}: r_result = remd;                 // REMU
      default: begin r_result = 32'b0; r_valid = 1'b0; end
    endcase
  end

  /* Register-immediate operations: funct3 */
  reg [31:0] i_result;
  reg        i_valid;
  always @* begin
    i_valid = 1'b1;
    case (f3)
      3'b000:  i_result = a + i_imm;                         // ADDI
      3'b111:  i_result = a & i_imm;                         // ANDI
      3'b110:  i_result = a | i_imm;                         // ORI
      default: begin i_result = 32'b0; i_valid = 1'b0; end
    endcase
  end

  /* Bus towards the quadram: stable during EXEC and MEM (same instr, same registers) */
  wire [31:0] mem_addr = a + ((opcode == STORE) ? s_imm : i_imm);
  assign address     = mem_addr[11:0];
  assign dataToWrite = b;
  assign we          = (state == EXEC) && (opcode == STORE) && (f3 == 3'b010);

  assign dbg_reg = regs[dbg_sel];
  assign halted  = (state == HALT);

  /* Main state machine */
  integer index;
  always @(posedge clock) begin
    if (reset) begin
      state   <= FETCH;
      pc      <= 12'd0;
      illegal <= 1'b0;
      for (index = 0; index < 32; index = index + 1)
        regs[index] <= 32'd0;
    end else begin
      case (state)
        FETCH: state <= EXEC;
        EXEC: begin
          state <= FETCH;
          pc    <= pc + 12'd1;
          case (opcode)
            ARITHMETIC:
              if (!r_valid)     illegal  <= 1'b1;
              else if (rd != 0) regs[rd] <= r_result;
            IMM_ARITHMETIC:
              if (!i_valid)     illegal  <= 1'b1;
              else if (rd != 0) regs[rd] <= i_result;
            LOAD:
              if (f3 == 3'b010) begin       // lw: wait for the quadram
                state <= MEM;
                pc    <= pc;
              end else
                illegal <= 1'b1;
            STORE:                           // sw: the quadram writes at the end of EXEC
              if (f3 != 3'b010) illegal <= 1'b1;
            EBREAK: begin
              state <= HALT;
              pc    <= pc;
            end
            default: illegal <= 1'b1;
          endcase
        end
        MEM: begin                           // lw: the word read is valid now
          if (rd != 0) regs[rd] <= dataToRead;
          pc    <= pc + 12'd1;
          state <= FETCH;
        end
        default: state <= HALT;              // HALT: stays here until reset
      endcase
    end
  end

endmodule
