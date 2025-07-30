`include "defines.sv"
`include "alu_opA.v"
`include "alu_opB.v"
`include "alu_two_op.v"

module alu_top (
    clk, rst, ce, inp_valid, mode, cmd, cin, opa, opb,
    res, cout, oflow, g, l, e, err
);
	
    	input  wire                   clk;
    	input  wire                   rst;
    	input  wire                   ce;
    	input  wire [1:0]             inp_valid;
    	input  wire                   mode;
    	input  wire [`CMD_WIDTH-1:0]  cmd;
    	input  wire                   cin;
    	input  wire [`OP_WIDTH-1:0]   opa;
    	input  wire [`OP_WIDTH-1:0]   opb;

    	`ifdef MUL_OP
        	output reg [(2*`OP_WIDTH)-1:0] res;
    	`else
        	output reg [`OP_WIDTH:0] res;
    	`endif
    
    	output reg                    cout;
    	output reg                    oflow;
    	output reg                    g;
    	output reg                    l;
    	output reg                    e;
    	output reg                    err;

    	function is_opA_only;
        	input [`CMD_WIDTH-1:0] c; input m;
        	begin //{
            	if (m == 1) is_opA_only = (c == `INC_A || c == `DEC_A);
            	else        is_opA_only = (c == `NOT_A || c == `SHL1_A || c == `SHR1_A);
        	end //}
    	endfunction

    	function is_opB_only;
        	input [`CMD_WIDTH-1:0] c; input m;
        	begin //{
            	if (m == 1) is_opB_only = (c == `INC_B || c == `DEC_B);
            	else        is_opB_only = (c == `NOT_B || c == `SHL1_B || c == `SHR1_B);
        	end //}
    	endfunction

    	function is_two_op;
        	input [`CMD_WIDTH-1:0] c; input m;
        	begin //{
            	if (m == 1)
                	is_two_op = (c == `ADD || c == `SUB || c == `ADD_CIN || c == `SUB_CIN || c == `CMP || c == `INC_MUL || c == `SHL_MUL || c == `ADD_SIGN || c == `SUB_SIGN);
            	else
                	is_two_op = (c == `AND || c == `NAND || c == `OR || c == `NOR || c == `XOR || c == `XNOR || c == `ROL || c == `ROR);
        	end //}
    	endfunction

    	wire valid_cmd = is_opA_only(cmd, mode) || is_opB_only(cmd, mode) || is_two_op(cmd, mode);

    	wire valid_inp = (is_opA_only(cmd, mode) && inp_valid[0]) || (is_opB_only(cmd, mode) && inp_valid[1]) || (is_two_op(cmd, mode) && inp_valid == 2'b11);

    	wire is_mul = (mode == 1) && (cmd == `INC_MUL || cmd == `SHL_MUL);
        
        //Temp inputs
    	reg [`CMD_WIDTH-1:0]   cmd_r;
    	reg [1:0]              inp_valid_r;
    	reg                    mode_r;
    	reg [`OP_WIDTH-1:0]    opa_r, opb_r;
    	reg                    cin_r;
    	reg                    is_mul_r, err_r;
    	reg                    is_mul_mul;
    	
    	//Temp output for MUL
    	`ifdef MUL_OP
        	reg [(2*`OP_WIDTH)-1:0] res_mul;
    	`else
         	reg [`OP_WIDTH:0] res_mul;
    	`endif
        
        //wires for ports
    	`ifdef MUL_OP
        	wire [(2*`OP_WIDTH)-1:0] res_two_op;
    	`else
         	wire [`OP_WIDTH:0] res_two_op;
    	`endif

        wire [`OP_WIDTH:0] res_opa, res_opb;
    	wire cout_opa, oflow_opa;
    	wire cout_opb, oflow_opb;
    	wire cout_two_op, oflow_two_op, err_two_op, g_two_op, l_two_op, e_two_op;

    	wire en_two_op_r = is_two_op(cmd_r, mode_r) && (inp_valid_r == 2'b11);
    	wire en_opa_r    = is_opA_only(cmd_r, mode_r) && (inp_valid_r[0]);
    	wire en_opb_r    = is_opB_only(cmd_r, mode_r) && (inp_valid_r[1]);
	
    	alu_opA aluA (.enable(en_opa_r), .mode(mode_r), .cmd(cmd_r), .opa(opa_r),.res(res_opa), .cout(cout_opa), .oflow(oflow_opa));
    	alu_opB aluB (.enable(en_opb_r), .mode(mode_r), .cmd(cmd_r), .opb(opb_r),.res(res_opb), .cout(cout_opb), .oflow(oflow_opb));
    	alu_two_op alu2 (.enable(en_two_op_r), .mode(mode_r), .cmd(cmd_r), .opa(opa_r), .opb(opb_r), .cin(cin_r), .res(res_two_op), .cout(cout_two_op), .oflow(oflow_two_op), .err(err_two_op), .g(g_two_op), .l(l_two_op), .e(e_two_op));

    	always @(posedge clk or posedge rst) begin //{
        	if (rst) begin //{
            		cmd_r <= 0; inp_valid_r <= 0; mode_r <= 0; opa_r <= 0; opb_r <= 0; cin_r <= 0;
            		is_mul_r <= 0; err_r <= 0;
            		is_mul_mul <= 0;  
            		res <= 0; cout <= 0; oflow <= 0; g <= 0; l <= 0; e <= 0; err <= 0;
            		res_mul <= 0; 
        	end //}
        	else if (ce) begin //{
            		// Inputs in temp
            		if (valid_cmd && valid_inp) begin //{
                		// Valid 
                		cmd_r <= cmd;
                		inp_valid_r <= inp_valid;
                		mode_r <= mode;
                		opa_r <= opa;
                		opb_r <= opb;
                		cin_r <= cin;
                		is_mul_r <= is_mul;
                		err_r   <= 0;
            		end //}
            		else begin //{ 
				        //Error                
                		cmd_r <= 0; inp_valid_r <= 0; mode_r <= 0;
                		opa_r <= 0; opb_r <= 0; cin_r <= 0;
                		is_mul_r <= 0; 
                		err_r   <= 1; 
            		end //}

            		is_mul_mul <= is_mul_r;
            		
            		// Extra delay
            		if (is_mul_r) begin //{
                		res_mul  <= res_two_op;
            		end //}

            		// 2op > MUL
          	 	    if (!is_mul_r) begin //{
                		if (err_r) begin //{
                    			res <= 0; cout <= 0; oflow <= 0; g <= 0; l <= 0; e <= 0; err <= 1;
                		end //}
                		else if (en_two_op_r) begin //{
                    			res   <= res_two_op;
                    			cout  <= cout_two_op;
                    			oflow <= oflow_two_op;
                    			err   <= err_two_op;
                    			g     <= g_two_op;
                    			l     <= l_two_op;
                   			    e     <= e_two_op;
                		end //}
                		else if (en_opa_r) begin //{
                    			res   <= res_opa;
                    			cout  <= cout_opa;
                    			oflow <= oflow_opa;
                    			err   <= 0; g <= 0; l <= 0; e <= 0;
                		end //}
                		else if (en_opb_r) begin //{
                    			res   <= res_opb;
                    			cout  <= cout_opb;
                    			oflow <= oflow_opb;
                   			    err   <= 0; g <= 0; l <= 0; e <= 0;
                		end //}
            		end //}
            		else if (is_mul_mul) begin //{
                    		res   <= res_mul;
                    		cout  <= 0;
                    		oflow <= 0;
                    		err   <= 0;
                    		g     <= 0;
                    		l     <= 0;
                    		e     <= 0;
            		end //}
			else begin //{
				//Mul 2nd cycle makes values 0
				     res   <= 0;
                     cout  <= 0;
                     oflow <= 0;
                     err   <= 0;
                     g     <= 0;
                     l     <= 0;
                     e     <= 0;

			end //}
				
        end //}
        //~CE - HOLDS value
   end //}
endmodule
