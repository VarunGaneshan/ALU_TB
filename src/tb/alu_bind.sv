// This file binds the assertion interface to the ALU design/interface
bind alu_if alu_assertions alu_if_assert_inst (
  .clk(clk),
  .rst(rst),
  .ce(ce),
  .mode(mode),
  .cmd(cmd),
  .inp_valid(inp_valid),
  .cin(cin),
  .opa(opa),
  .opb(opb),
  .res(res),
  .cout(cout),
  .oflow(oflow),
  .g(g),
  .l(l),
  .e(e),
  .err(err)
);
