/*
 Description: processor of part 7, able to run the code produced by a C compiler
              (gcc -march=rv32im -mabi=ilp32).

 Derived from exo/p6/riscvproc_fpga.v (same state machine, same bus towards the
 quadram, still synthesizable), with the changes needed by the compiler:
  - byte addresses, as in the RISC-V specification: pc advances by 4, the ROM is
    read with pc[ROM_AW+1:2] and the quadram receives the word address addr[13:2];
  - all the RV32I instructions except fence and the CSR instructions: lui, auipc,
    jal, jalr, the six branches, the comparisons, xor, the arithmetic shifts...
  - ecall and ebreak stop the processor.
 Only the word accesses lw and sw are supported: the quadram has no byte enable,
 so lb, lh, lbu, lhu, sb and sh set 'illegal'.
*/

module riscvproc_rv32 #(
  parameter PROG_FILE = "programme.txt",     // program loaded into the ROM
  parameter ROM_AW    = 10                   // ROM of 2**ROM_AW instructions (4 KB)
) (
  input         clock,
  input         reset,        // synchronous reset, active high
  output [11:0] address,      // word address towards the quadram (byte address / 4)
  output [31:0] dataToWrite,
  input  [31:0] dataToRead,
  output        we,
  input  [4:0]  dbg_sel,      // register shown on the board
  output [31:0] dbg_reg,
  output        halted,       // ebreak or ecall reached
  output reg    illegal       // an unsupported instruction has been skipped
);

  localparam [1:0] FETCH = 2'd0, EXEC = 2'd1, MEM = 2'd2, HALT = 2'd3;

  /* Opcodes - Chapter 24, RV32/64G Instruction Set Listings */
  localparam [6:0] OP     = 7'b0110011,    // register-register
                   OP_IMM = 7'b0010011,    // register-immediate
                   LOAD   = 7'b0000011,
                   STORE  = 7'b0100011,
                   BRANCH = 7'b1100011,
                   JAL    = 7'b1101111,
                   JALR   = 7'b1100111,
                   LUI    = 7'b0110111,
                   AUIPC  = 7'b0010111,
                   SYSTEM = 7'b1110011;    // ecall, ebreak

  reg [1:0]  state;
  reg [31:0] pc;                        // byte address of the instruction
  reg [31:0] instr;                     // instruction read from the ROM
  reg [31:0] regs [0:31];               // regfile
  reg [31:0] rom  [0:(1<<ROM_AW)-1];    // program memory

  initial $readmemh(PROG_FILE, rom);

  // synchronous read: the instruction at pc is valid one period later
  always @(posedge clock)
    instr <= rom[pc[ROM_AW+1:2]];

  /* Instruction fields and immediates - Chapter 2.3 */
  wire [6:0]  opcode = instr[6:0];
  wire [2:0]  f3     = instr[14:12];
  wire [6:0]  f7     = instr[31:25];
  wire [4:0]  rd     = instr[11:7];
  wire [31:0] a      = regs[instr[19:15]];   // rs1
  wire [31:0] b      = regs[instr[24:20]];   // rs2
  wire [31:0] i_imm  = {{20{instr[31]}}, instr[31:20]};
  wire [31:0] s_imm  = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  wire [31:0] b_imm  = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
  wire [31:0] u_imm  = {instr[31:12], 12'b0};
  wire [31:0] j_imm  = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};

  /* RV32M multiplier and divider, as in riscvproc_fpga.v */
  wire               a_signed   = (f3 == 3'b001) || (f3 == 3'b010);  // MULH, MULHSU
  wire               b_signed   = (f3 == 3'b001);                    // MULH
  wire signed [32:0] ma         = {a_signed & a[31], a};
  wire signed [32:0] mb         = {b_signed & b[31], b};
  wire signed [65:0] prod       = ma * mb;
  wire               div_signed = (f3 == 3'b100) || (f3 == 3'b110);  // DIV, REM
  wire               neg_a      = div_signed & a[31];
  wire               neg_b      = div_signed & b[31];
  wire [31:0]        ua         = neg_a ? -a : a;
  wire [31:0]        ub         = neg_b ? -b : b;
  wire [31:0]        uq         = ua / ub;
  wire [31:0]        ur         = ua % ub;
  wire [31:0]        quot       = (b == 0) ? 32'hFFFFFFFF : ((neg_a ^ neg_b) ? -uq : uq);
  wire [31:0]        remd       = (b == 0) ? a : (neg_a ? -ur : ur);

  /* ALU shared by OP and OP_IMM: for OP_IMM the second operand is the immediate.
     The arithmetic shift is computed apart: in a ? : with an unsigned branch,
     $signed(a) >>> n would become a logical shift. */
  wire [31:0] op2     = (opcode == OP) ? b : i_imm;
  wire [4:0]  shamt   = op2[4:0];
  wire [31:0] sra_res = $signed(a) >>> shamt;
  wire        alt     = (f7 == 7'b0100000);                         // SUB, SRA, SRAI
  reg  [31:0] alu;
  reg         alu_ok;
  always @* begin
    alu_ok = 1'b1;
    if (opcode == OP && f7 == 7'b0000001) begin                     // M extension
      case (f3)
        3'b000:         alu = prod[31:0];                            // MUL
        3'b001, 3'b010,
        3'b011:         alu = prod[63:32];                           // MULH, MULHSU, MULHU
        3'b100, 3'b101: alu = quot;                                  // DIV, DIVU
        default:        alu = remd;                                  // REM, REMU
      endcase
    end else begin
      case (f3)
        3'b000:  alu = (opcode == OP && alt) ? a - op2 : a + op2;   // ADD, SUB, ADDI
        3'b001:  alu = a << shamt;                                   // SLL, SLLI
        3'b010:  alu = {31'b0, $signed(a) < $signed(op2)};           // SLT, SLTI
        3'b011:  alu = {31'b0, a < op2};                             // SLTU, SLTIU
        3'b100:  alu = a ^ op2;                                      // XOR, XORI
        3'b101:  alu = alt ? sra_res : a >> shamt;                   // SRL, SRA, SRLI, SRAI
        3'b110:  alu = a | op2;                                      // OR, ORI
        default: alu = a & op2;                                      // AND, ANDI
      endcase
      // funct7 must be 0000000, or 0100000 for SUB and the arithmetic shifts
      if (opcode == OP || f3 == 3'b001 || f3 == 3'b101)
        alu_ok = (f7 == 7'b0000000) || (alt && (f3 == 3'b101 || (f3 == 3'b000 && opcode == OP)));
    end
  end

  /* Branch condition */
  reg take;
  always @* begin
    case (f3)
      3'b000:  take = (a == b);                                      // BEQ
      3'b001:  take = (a != b);                                      // BNE
      3'b100:  take = ($signed(a) <  $signed(b));                    // BLT
      3'b101:  take = ($signed(a) >= $signed(b));                    // BGE
      3'b110:  take = (a <  b);                                      // BLTU
      default: take = (a >= b);                                      // BGEU
    endcase
  end
  wire branch_ok = (f3 != 3'b010) && (f3 != 3'b011);

  /* Bus towards the quadram: stable during EXEC and MEM (same instr, same registers) */
  wire [31:0] mem_addr = a + ((opcode == STORE) ? s_imm : i_imm);   // byte address
  assign address     = mem_addr[13:2];
  assign dataToWrite = b;
  assign we          = (state == EXEC) && (opcode == STORE) && (f3 == 3'b010);

  assign dbg_reg = regs[dbg_sel];
  assign halted  = (state == HALT);

  /* Main state machine */
  integer index;
  always @(posedge clock) begin
    if (reset) begin
      state   <= FETCH;
      pc      <= 32'd0;
      illegal <= 1'b0;
      for (index = 0; index < 32; index = index + 1)
        regs[index] <= 32'd0;
    end else begin
      case (state)
        FETCH: state <= EXEC;
        EXEC: begin
          state <= FETCH;
          pc    <= pc + 32'd4;
          case (opcode)
            OP, OP_IMM:
              if (!alu_ok)      illegal  <= 1'b1;
              else if (rd != 0) regs[rd] <= alu;
            LUI:
              if (rd != 0) regs[rd] <= u_imm;
            AUIPC:
              if (rd != 0) regs[rd] <= pc + u_imm;
            JAL: begin
              if (rd != 0) regs[rd] <= pc + 32'd4;
              pc <= pc + j_imm;
            end
            JALR: begin
              if (rd != 0) regs[rd] <= pc + 32'd4;
              pc <= (a + i_imm) & ~32'd1;
            end
            BRANCH:
              if (!branch_ok) illegal <= 1'b1;
              else if (take)  pc      <= pc + b_imm;
            LOAD:
              if (f3 == 3'b010) begin         // lw: wait for the quadram
                state <= MEM;
                pc    <= pc;
              end else
                illegal <= 1'b1;
            STORE:                             // sw: the quadram writes at the end of EXEC
              if (f3 != 3'b010) illegal <= 1'b1;
            SYSTEM: begin                      // ecall, ebreak
              state <= HALT;
              pc    <= pc;
            end
            default: illegal <= 1'b1;
          endcase
        end
        MEM: begin                             // lw: the word read is valid now
          if (rd != 0) regs[rd] <= dataToRead;
          pc    <= pc + 32'd4;
          state <= FETCH;
        end
        default: state <= HALT;                // HALT: stays here until reset
      endcase
    end
  end

endmodule
