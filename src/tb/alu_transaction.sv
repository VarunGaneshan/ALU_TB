class alu_transaction;
  rand bit                     ce, mode, cin;
  rand bit [1:0]               inp_valid;
  rand bit [`CMD_WIDTH-1:0]    cmd;
  rand bit [`OP_WIDTH-1:0]     opa, opb;
  
  `ifdef MUL_OP
    bit [(2*`OP_WIDTH)-1:0] res;
  `else
    bit [`OP_WIDTH:0] res;
  `endif
  
  bit cout, oflow, g, l, e, err;

  constraint ce_c {
    ce dist {1 := 98, 0 := 2}; // Clock enable mostly active
  }

  constraint mode_c {
    mode dist {0 := 50, 1 := 50}; // Equal distribution between arithmetic and logical in base test
  }  
  
  constraint cin_c {
    cin dist {0 := 75, 1 := 25}; // Carry in occasionally
  }

  // Constraint for valid commands based on mode
  constraint cmd_mode_c {
    if (mode == 1) {
      cmd inside {`ADD, `SUB, `ADD_CIN, `SUB_CIN, `INC_A, `DEC_A, `INC_B, `DEC_B, `CMP, `INC_MUL, `SHL_MUL};
    } else {
      cmd inside {`AND, `NAND, `OR, `NOR, `XOR, `XNOR, `NOT_A, `NOT_B, `SHR1_A, `SHL1_A, `SHR1_B, `SHL1_B, `ROL, `ROR};
    }
  }
  
  // Input valid constraints based on command
  constraint inp_valid_c { 
     if (mode == 1) {
      if (cmd == `INC_A || cmd == `DEC_A) {
        inp_valid == 2'b01;
      } else if (cmd == `INC_B || cmd == `DEC_B) {
        inp_valid == 2'b10;
      } else {
        inp_valid == 2'b11;
      }
    } else { // mode == 0
      if (cmd == `NOT_A || cmd == `SHL1_A || cmd == `SHR1_A) {
        inp_valid == 2'b01;
      } else if (cmd == `NOT_B || cmd == `SHL1_B || cmd == `SHR1_B) {
        inp_valid == 2'b10;
      } else {
        inp_valid == 2'b11;
      }
    }
  }

  // Deep copy function for blue print pattern
  virtual function alu_transaction clone();
    alu_transaction cloned_copy = new();
    cloned_copy.ce = this.ce;
    cloned_copy.mode = this.mode;
    cloned_copy.cin = this.cin;
    cloned_copy.inp_valid = this.inp_valid;
    cloned_copy.cmd = this.cmd;
    cloned_copy.opa = this.opa;
    cloned_copy.opb = this.opb;
    return cloned_copy;
  endfunction

endclass


class alu_arith extends alu_transaction;
  constraint cmd_mode_c {
    cmd inside {`ADD, `SUB, `ADD_CIN, `SUB_CIN, `INC_A, `DEC_A, `INC_B, `DEC_B, `CMP, `INC_MUL, `SHL_MUL};
  }

  constraint mode_c {
    mode == 1; 
  }

  constraint inp_valid_c { 
      if (cmd == `INC_A || cmd == `DEC_A) {
        inp_valid == 2'b01;
      } else if (cmd == `INC_B || cmd == `DEC_B) {
        inp_valid == 2'b10;
      } else {
        inp_valid dist {2'b11 := 50, 2'b01 := 25, 2'b10 := 25}; 
      }
    }

  virtual function alu_transaction clone();
    alu_arith cloned_copy = new();
    cloned_copy.ce = this.ce;
    cloned_copy.mode = this.mode;
    cloned_copy.cin = this.cin;
    cloned_copy.inp_valid = this.inp_valid;
    cloned_copy.cmd = this.cmd;
    cloned_copy.opa = this.opa;
    cloned_copy.opb = this.opb;
    return cloned_copy;
  endfunction

endclass

class alu_logical extends alu_transaction;
  constraint cmd_mode_c {
    cmd inside {`AND, `NAND, `OR, `NOR, `XOR, `XNOR, `NOT_A, `NOT_B, `SHR1_A, `SHL1_A, `SHR1_B, `SHL1_B, `ROL, `ROR};
  }

  constraint mode_c {
    mode == 0; 
  }

  constraint inp_valid_c { 
      if (cmd == `NOT_A || cmd == `SHL1_A || cmd == `SHR1_A) {
        inp_valid == 2'b01;
      } else if (cmd == `NOT_B || cmd == `SHL1_B || cmd == `SHR1_B) {
        inp_valid == 2'b10;
      } else {
        inp_valid dist {2'b11 := 50, 2'b01 := 25, 2'b10 := 25};
      }
    }

  virtual function alu_transaction clone();
    alu_logical cloned_copy = new();
    cloned_copy.ce = this.ce;
    cloned_copy.mode = this.mode;
    cloned_copy.cin = this.cin;
    cloned_copy.inp_valid = this.inp_valid;
    cloned_copy.cmd = this.cmd;
    cloned_copy.opa = this.opa;
    cloned_copy.opb = this.opb;
    return cloned_copy;
  endfunction

endclass
