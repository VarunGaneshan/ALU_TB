 interface alu_if(input bit clk, rst);
  logic                     ce, mode, cin; 
  logic [1:0]               inp_valid;
  logic [`CMD_WIDTH-1:0]    cmd;
  logic [`OP_WIDTH-1:0]     opa, opb;
  
  `ifdef MUL_OP
    logic [(2*`OP_WIDTH)-1:0] res;
  `else
    logic [`OP_WIDTH:0] res;
  `endif
  
  logic cout, oflow, g, l, e, err;

  clocking drv_cb @(posedge clk);
    //default input #1 output #1;
    output ce, inp_valid, mode, cmd, cin, opa, opb;
  endclocking

  clocking mon_cb @(posedge clk);
    //default input #1 output #1;
    input res, cout, oflow, g, l, e, err; 
  endclocking

  clocking ref_cb @(posedge clk);
    //default input #1 output #1;
    input rst;
  endclocking

  modport DRV(clocking drv_cb);
  modport MON(clocking mon_cb);
  modport REF_SB(clocking ref_cb);
endinterface
