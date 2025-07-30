class alu_reference_model;
  alu_transaction ref_trans;
  mailbox #(alu_transaction) mbx_dr;
  mailbox #(alu_transaction) mbx_rs;
  virtual alu_if.REF_SB vif;

  function new(mailbox #(alu_transaction) mbx_dr, mailbox #(alu_transaction) mbx_rs, virtual alu_if.REF_SB vif);
    this.mbx_dr = mbx_dr;
    this.mbx_rs = mbx_rs;
    this.vif = vif;
  endfunction

  function bit is_two_op;
    input [`CMD_WIDTH-1:0] c;
    input m;
    begin
      if (m == 1)
        is_two_op = (c == `ADD || c == `SUB || c == `ADD_CIN || c == `SUB_CIN || c == `CMP || c == `INC_MUL || c == `SHL_MUL);
      else
        is_two_op = (c == `AND || c == `NAND || c == `OR || c == `NOR || c == `XOR || c == `XNOR || c == `ROL || c == `ROR);
    end
  endfunction

  task calculate_expected(alu_transaction trans);
    `ifdef MUL_OP
      logic [(2*`OP_WIDTH)-1:0] t_res;
    `else
      logic [`OP_WIDTH:0] t_res;
    `endif
    logic t_cout, t_oflow, t_g, t_l, t_e, t_err;
    integer rot_amt;
    logic opb_err_bits;
    logic [`OP_WIDTH-1:0] shl_t;
    logic [`OP_WIDTH-1:0] t_opa, t_opb;
    bit t_cin;
    bit [1:0] t_inp_valid;
    bit t_mode;
    bit [`CMD_WIDTH-1:0] t_cmd;
    bit t_rst, t_ce;
    
    // Extract values from transaction
    t_opa = trans.opa;
    t_opb = trans.opb;
    t_cin = trans.cin;
    t_inp_valid = trans.inp_valid;
    t_mode = trans.mode;
    t_cmd = trans.cmd;
    t_ce = trans.ce;  
    t_rst = vif.ref_cb.rst;  // Get reset from interface
    
    // Check for reset condition - when reset is active, all outputs are 0
    if (t_rst) begin
      $display("[%0t] REFERENCE MODEL: Reset active - all outputs set to 0", $time);
      trans.res = 0;
      trans.cout = 0;
      trans.oflow = 0;
      trans.g = 0;
      trans.l = 0;
      trans.e = 0;
      trans.err = 0;
      return;
    end
    
    // Normal operation - check for error conditions
    if ((t_mode && (t_cmd > `SHL_MUL)) || (!t_mode && (t_cmd > `ROR))) 
      t_err = 1;
    else if (t_mode && ((t_cmd == `INC_A || t_cmd == `DEC_A) && !t_inp_valid[0] ))
      t_err = 1;
    else if (t_mode && ((t_cmd == `INC_B || t_cmd == `DEC_B) && !t_inp_valid[1] ))
      t_err = 1;
    else if (t_mode && (t_cmd <= `SHL_MUL) && is_two_op(t_cmd, t_mode) && (t_inp_valid != 2'b11))
      t_err = 1;
    else if (!t_mode && ((t_cmd == `NOT_A || t_cmd == `SHL1_A || t_cmd == `SHR1_A) && !t_inp_valid[0]))
      t_err = 1;
    else if (!t_mode && ((t_cmd == `NOT_B || t_cmd == `SHL1_B || t_cmd == `SHR1_B) && !t_inp_valid[1]))
      t_err = 1;
    else if (!t_mode && is_two_op(t_cmd, t_mode) && (t_inp_valid != 2'b11))
      t_err = 1;

    if(t_ce) begin
        if (t_err) begin
          t_res = 0; t_cout = 0; t_oflow = 0; t_g = 0; t_l = 0; t_e = 0;
          $display("[%0t] REFERENCE MODEL: Error condition detected - err=1", $time);
        end
        else if (t_mode) begin
          case (t_cmd)
            `ADD      : begin t_res[`OP_WIDTH:0] = t_opa + t_opb; t_cout = t_res[`OP_WIDTH]; end
            `SUB      : begin t_res[`OP_WIDTH:0] = t_opa - t_opb; t_oflow = (t_opa < t_opb); end
            `ADD_CIN  : begin t_res[`OP_WIDTH:0] = t_opa + t_opb + t_cin; t_cout = t_res[`OP_WIDTH]; end
            `SUB_CIN  : begin t_res[`OP_WIDTH:0] = t_opa - t_opb - t_cin; t_oflow = (t_opa < t_opb || (t_opa==t_opb && t_cin==1)); end
            `CMP      : begin t_g = (t_opa > t_opb); t_l = (t_opa < t_opb); t_e = (t_opa == t_opb); t_res = 0; end
            `INC_A    : begin t_res[`OP_WIDTH:0] = t_opa + 1; t_cout = t_res[`OP_WIDTH]; end
            `DEC_A    : begin t_res[`OP_WIDTH:0] = t_opa - 1; t_oflow = (t_opa == 0); end
            `INC_B    : begin t_res[`OP_WIDTH:0] = t_opb + 1; t_cout = t_res[`OP_WIDTH]; end
            `DEC_B    : begin t_res[`OP_WIDTH:0] = t_opb - 1; t_oflow = (t_opb == 0); end
            `INC_MUL  : begin t_res = (t_opa + 1) * (t_opb + 1); end
            `SHL_MUL  : begin shl_t = t_opa << 1; t_res = shl_t * t_opb; end
          endcase
        end
        else begin
          rot_amt = t_opb[$clog2(`OP_WIDTH)-1:0];
          opb_err_bits = |t_opb[`OP_WIDTH-1:$clog2(`OP_WIDTH)];
          case (t_cmd)
            `AND   : t_res[`OP_WIDTH-1:0] = t_opa & t_opb;
            `NAND  : t_res[`OP_WIDTH-1:0] = ~(t_opa & t_opb);
            `OR    : t_res[`OP_WIDTH-1:0] = t_opa | t_opb;
            `NOR   : t_res[`OP_WIDTH-1:0] = ~(t_opa | t_opb);
            `XOR   : t_res[`OP_WIDTH-1:0] = t_opa ^ t_opb;
            `XNOR  : t_res[`OP_WIDTH-1:0] = ~(t_opa ^ t_opb);
            `ROL: begin
              if (opb_err_bits)
                t_err = 1;
              t_res[`OP_WIDTH-1:0] = (t_opa << rot_amt) | (t_opa >> (`OP_WIDTH - rot_amt));
            end
            `ROR: begin
              if (opb_err_bits)
                t_err = 1;
              t_res[`OP_WIDTH-1:0] = (t_opa >> rot_amt) | (t_opa << (`OP_WIDTH - rot_amt));
            end
            `NOT_A : t_res[`OP_WIDTH-1:0] = ~t_opa;
            `NOT_B : t_res[`OP_WIDTH-1:0] = ~t_opb;
            `SHR1_A: t_res[`OP_WIDTH-1:0] = t_opa >> 1;
            `SHL1_A: t_res[`OP_WIDTH-1:0] = t_opa << 1;
            `SHR1_B: t_res[`OP_WIDTH-1:0] = t_opb >> 1;
            `SHL1_B: t_res[`OP_WIDTH-1:0] = t_opb << 1;
          endcase
        end
        trans.res = t_res;
        trans.cout = t_cout;
        trans.oflow = t_oflow;
        trans.g = t_g;
        trans.l = t_l;
        trans.e = t_e;
        trans.err = t_err;
    end
    else  begin
      // Store current outputs as previous state for next CE=0 operation
    end
  endtask

  task start();
    for(int i = 0; i < `no_of_trans; i++) begin
      mbx_dr.get(ref_trans);
      calculate_expected(ref_trans);
      mbx_rs.put(ref_trans);
      $display("[%0t] REFERENCE MODEL: Transaction %0d - Expected res=0x%h cout=%0b oflow=%0b g=%0b l=%0b e=%0b err=%0b", $time, i, ref_trans.res, ref_trans.cout, ref_trans.oflow, ref_trans.g, ref_trans.l, ref_trans.e, ref_trans.err);
    end
  endtask
endclass
