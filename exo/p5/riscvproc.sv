 /*
 Authors: Teo Biton
 Date: 07.11.2025
 Description: Simple single-cycle RISC-V processor (RV32I) for simulation
 
 RISC-V Unprivileged Specifications Volume I: https://riscv.org/technical/specifications/
 Chapters and pages from this Volume are referenced for help (see the one on madoc).
*/

module riscvproc (
  input             clock,
  input             reset,        // synchronous reset, active high
  output reg [11:0] address,      // bus towards the quadram
  output reg [31:0] dataToWrite,
  input      [31:0] dataToRead,
  output reg        we
);
  // Parameters declaration
  parameter 
   
    DataWidth = 32,           // data bus width
    AddrWidth = 12,           // address bus width
    MemSize   = 1<<AddrWidth; // memory size

  // Local parameters declaration
  localparam int unsigned InstrSize = 32; // instructions are on 32 bits
  localparam int unsigned NRegs   = 32;   // number of internal registers

  reg[DataWidth-1:0] memory[0:MemSize-1]; // memory declaration
  reg[InstrSize-1:0] instr;               // instruction register declaration
  reg[AddrWidth-1:0] pc;                  // program counter
  reg[DataWidth-1:0] regs[0:NRegs-1];     // regfile declaration
  reg[AddrWidth-1:0] addr;                // address
    reg[63:0]          prod;                // 64-bit product for MULH, MULHSU, MULHU

  /*
    Instruction Fields
    Chapter 2.2 Base Instruction Formats
  */

  // instruction identifiers - Pages 15, 16
  `define OPCODE  instr[6:0]     // opcode
  `define F3      instr[14:12]   // funct3
  `define F7      instr[31:25]   // funct7

  // register fields - Pages 15, 16
  `define RS1   instr[19:15]    // source register 1
  `define RS2   instr[24:20]    // source register 2
  `define RD    instr[11:7]     // destination register

  // immediates - Pages 15, 16
  `define I_IMM   {{20{instr[31]}},instr[31:20]}//$signed(instr[31:20])                 // I-type immediate
  `define S_IMM   {{20{instr[31]}},instr[31:25],instr[11:7] } // S-type immediate

  // addresses (for Load and Store instructions
  // chapter 2.6 Load and Store Instructions
  `define LOAD_OFFSET     instr[31:20] << 12
  `define STORE_OFFSET   (instr[31:25] << 5 | instr[11:7]) << 12

  /*
    Instruction Declarations
    Chapter 24 RV32/64G Instruction Set Listings
    Page 130
  */

  /* Opcodes */
  `define ARITHMETIC        7'b0110011
  `define IMM_ARITHMETIC    7'b0010011
  `define LOAD              7'b0000011
  `define STORE             7'b0100011
  `define EBREAK            7'b1110011

  /* Arithmetic instructions
     Format:    {Funct3, Funct7    } */
  `define ADD   {3'b000, 7'b0000000}
  `define SUB   {3'b000, 7'b0100000}
  `define SLL   {3'b001, 7'b0000000}  // Shift Left
  `define SRL   {3'b101, 7'b0000000}  // Shift Right
  
  /* RV32M instructions - Chapter "M" Standard Extension
     Format:    {Funct3, Funct7    } */
  `define MUL    {3'b000, 7'b0000001}  // Multiply (low 32 bits)
  `define MULH   {3'b001, 7'b0000001}  // Multiply High, signed x signed
  `define MULHSU {3'b010, 7'b0000001}  // Multiply High, signed x unsigned
  `define MULHU  {3'b011, 7'b0000001}  // Multiply High, unsigned x unsigned
  `define DIV    {3'b100, 7'b0000001}  // Divide, signed
  `define DIVU   {3'b101, 7'b0000001}  // Divide, unsigned
  `define REM    {3'b110, 7'b0000001}  // Remainder, signed
  `define REMU   {3'b111, 7'b0000001}  // Remainder, unsigned

  /* Load instructions */
  `define LW    3'b010  // Load Word

  /* Store instructions */
  `define SW    3'b010  // Store Word

  /* Arithmetic immediates instructions */
  `define ADDI  3'b000  // Add Immediate
  `define ANDI  3'b111  // And Immediate
  `define ORI   3'b110  // Or Immediate

  /*
    Reset (start module)
  */
  integer index;

  // Optional program selection; keep the exercise's original default.
  string progfile;
  initial begin
    if (!$value$plusargs("prog=%s", progfile))
      progfile = "instr2.txt";
    $readmemh(progfile, memory);
    // initialize program counter to 0
    pc = 0;
    // initialize all registers to 0
    for (index = 0; index < NRegs; index = index + 1) begin
      regs[index] = 0;
    end
        // bus towards the quadram: not used yet, the data are still in the internal memory
    address     = 0;
    dataToWrite = 0;
    we          = 0;

  end

  /*
    Main cycle for one instruction
  */

  always begin // one instruction per clock period

    @(negedge clock);

    if (reset) begin
      // synchronous reset: same values as at the start of the simulation
      pc = 0;
      for (index = 0; index < NRegs; index = index + 1) begin
        regs[index] = 0;
      end
    end else begin

    instr = memory[pc];   // instruction fetch (blocking: executed in this same period)
    pc    = pc + 1;       // increment program counter
    addr  = 0;            // address initial value
    
    case(`OPCODE)        // decode instruction
      `ARITHMETIC: begin // Integer Register-Register Operations - Page 19
        case({`F3, `F7})
          `ADD: regs[`RD] = regs[`RS1] + regs[`RS2];
          `SUB: regs[`RD] = regs[`RS1] - regs[`RS2];
          `SRL: regs[`RD] = regs[`RS1] >> regs[`RS2][4:0];
          `SLL: regs[`RD] = regs[`RS1] << regs[`RS2][4:0];
                  // RV32M: multiplication
          `MUL:    regs[`RD] = regs[`RS1] * regs[`RS2];  // 32-bit target: low half
          `MULH:   begin
                     prod = {{32{regs[`RS1][31]}}, regs[`RS1]} * {{32{regs[`RS2][31]}}, regs[`RS2]};
                     regs[`RD] = prod[63:32];
                   end
          `MULHSU: begin
                     prod = {{32{regs[`RS1][31]}}, regs[`RS1]} * {32'b0, regs[`RS2]};
                     regs[`RD] = prod[63:32];
                   end
          `MULHU:  begin
                     prod = {32'b0, regs[`RS1]} * {32'b0, regs[`RS2]};
                     regs[`RD] = prod[63:32];
                   end
          // RV32M: division (no exception, the results are fixed by the spec)
          `DIV:    if (regs[`RS2] == 0)
                     regs[`RD] = 32'hFFFFFFFF;                     // division by 0: -1
                   else if (regs[`RS1] == 32'h80000000 && regs[`RS2] == 32'hFFFFFFFF)
                     regs[`RD] = 32'h80000000;                     // overflow: -2^31
                   else
                     regs[`RD] = $signed(regs[`RS1]) / $signed(regs[`RS2]);
          `DIVU:   if (regs[`RS2] == 0)
                     regs[`RD] = 32'hFFFFFFFF;                     // division by 0: 2^32-1
                   else
                     regs[`RD] = regs[`RS1] / regs[`RS2];
          `REM:    if (regs[`RS2] == 0)
                     regs[`RD] = regs[`RS1];                       // division by 0: dividend
                   else if (regs[`RS1] == 32'h80000000 && regs[`RS2] == 32'hFFFFFFFF)
                     regs[`RD] = 0;                                // overflow: 0
                   else
                     regs[`RD] = $signed(regs[`RS1]) % $signed(regs[`RS2]);
          `REMU:   if (regs[`RS2] == 0)
                     regs[`RD] = regs[`RS1];                       // division by 0: dividend
                   else
                     regs[`RD] = regs[`RS1] % regs[`RS2];  
          default: $display("erreur: mauvaise instruction arithmétique");
        endcase
      end
      `IMM_ARITHMETIC: begin // Integer Register-Immediate Instructions - Page 18
        case(`F3)
          `ADDI: regs[`RD] = regs[`RS1] + `I_IMM;
          `ANDI: regs[`RD] = regs[`RS1] & `I_IMM;
          `ORI:  regs[`RD] = regs[`RS1] | `I_IMM;
          default: $display("erreur: mauvaise instruction arithmétique immédiate");
        endcase
      end
      `LOAD: begin // Load and Store Instructions - Page 24
        case(`F3)
          `LW: begin
            address   = regs[`RS1] + `I_IMM;   // address on the bus (falling edge)
            @(negedge clock);                  // rising edge in between: the quadram samples the address
            regs[`RD] = dataToRead;            // the word read is valid now
          end
          default: $display("erreur: mauvaise instruction load");
        endcase
      end
      `STORE: begin // Load and Store Instructions - Page 24
        case(`F3)
            `SW: begin
            address     = regs[`RS1] + `S_IMM; // address and data on the bus
            dataToWrite = regs[`RS2];
            we          = 1;
            @(negedge clock);                  // rising edge in between: the quadram writes the word
            we          = 0;
          end
          default: $display("erreur: mauvaise instruction store");
        endcase
      end
      // Environment Call and Breakpoints - Page 27
      // Slight change from the spec, Ebreak finishes simulation
      `EBREAK: $finish;
      default: $display("erreur: mauvaise valeur dans op-code");
    endcase
    regs[0] = 0;
    
  end  // if (reset) ... else
  end
  
endmodule
