`timescale 1ns/1ns
`include "defines.sv"
`include "alu_pkg.sv"
`include "alu_if.sv"
`include "alu_design.sv"
`include "alu_assertions.sv"
`include "alu_bind.sv"

module top;
  import alu_pkg::*;

  bit clk;
  bit rst;

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst = 0;
   //#delay rst=1;
  end

  alu_if alu_intf(clk, rst);

  alu_design DUT(
    .CLK(clk),
    .RST(rst),
    .CE(alu_intf.ce),
    .INP_VALID(alu_intf.inp_valid),
    .MODE(alu_intf.mode),
    .CMD(alu_intf.cmd),
    .CIN(alu_intf.cin),
    .OPA(alu_intf.opa),
    .OPB(alu_intf.opb),
    .RES(alu_intf.res),
    .COUT(alu_intf.cout),
    .OFLOW(alu_intf.oflow),
    .G(alu_intf.g),
    .L(alu_intf.l),
    .E(alu_intf.e),
    .ERR(alu_intf.err)
  );
 
  alu_test basic_test;
  alu_arith_test arith_test;
  alu_logical_test logical_test;
  test_regression tb_regression;
  initial begin
    repeat(2) @(posedge clk);
    /*basic_test = new(alu_intf.DRV, alu_intf.MON, alu_intf.REF_SB);
    arith_test = new(alu_intf.DRV, alu_intf.MON, alu_intf.REF_SB);
    logical_test = new(alu_intf.DRV, alu_intf.MON, alu_intf.REF_SB); */
    tb_regression = new(alu_intf.DRV, alu_intf.MON, alu_intf.REF_SB);

    $display("===============================================");
    $display("          ALU SystemVerilog Testbench");
    $display("===============================================");
    $display("[%0t] Starting ALU verification...", $time);

    /*basic_test.run();
    arith_test.run();
    logical_test.run();*/
    tb_regression.run();
    $display("[%0t] ALU verification completed!", $time);
    $display("===============================================");
    repeat(10) @(posedge clk);
    $finish;
  end
  
endmodule

