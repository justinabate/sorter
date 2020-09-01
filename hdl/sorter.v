`timescale 1 ns / 1 ps

module sorter # (
    parameter DATA_WIDTH  = 16
)(
    // ctrl inputs
    input wire                    clk, // ACLK
    input wire                    rst, // ARESETn, active low
    // AXI stream               
    input wire [DATA_WIDTH-1:0]   din, // TDATA, nominally [63:0]
    input wire                    vld, // TVALID
    input wire                    sof, // TUSER, start of frame
    input wire                    eof, // TLAST, packet boundary
	// output ports
	output wire [DATA_WIDTH-1:0]  lvl1,
	output wire [DATA_WIDTH-1:0]  lvl2,
	output wire [DATA_WIDTH-1:0]  lvl3,
	output wire [DATA_WIDTH-1:0]  lvl4,
	output reg                    done
);

	reg [DATA_WIDTH-1:0] lvl1_1ff;
	reg [DATA_WIDTH-1:0] lvl2_1ff;
	reg [DATA_WIDTH-1:0] lvl3_1ff;
	reg [DATA_WIDTH-1:0] lvl4_1ff;

	// FSM states
	reg        [3:0] fsm_cs; // current state  
	localparam [3:0] IDLE  = 4'b0001; // wait for 1st number to arrive
	localparam [3:0] COMP1 = 4'b0010; // compare 2nd number to 1st
	localparam [3:0] COMP2 = 4'b0100; // compare 3rd number to list
	localparam [3:0] COMP3 = 4'b1000; // compare 4th number to list

	always @(posedge clk) begin
		if (!rst) begin
			fsm_cs <= IDLE;
			lvl1_1ff <= {(DATA_WIDTH){1'b0}};
			lvl2_1ff <= {(DATA_WIDTH){1'b0}};
			lvl3_1ff <= {(DATA_WIDTH){1'b0}};
			lvl4_1ff <= {(DATA_WIDTH){1'b0}};
			done <= 1'b0;
		end else begin
			case (fsm_cs)
		
				IDLE : begin
					if (vld && sof) begin : UPPER_PLACEMENT_1
						fsm_cs <= COMP1; // next clock edge compares 2nd number to 1st
						lvl1_1ff <= din; // catch 1st number before state transition
					end else begin
						fsm_cs <= IDLE;
					end
					done <= 1'b0;
				end
				
				COMP1 : begin
					if (vld) begin
						fsm_cs <= COMP2; // next state compares 3rd number to 1-2
						if (din > lvl1_1ff) begin : UPPER_PLACEMENT_2
							lvl1_1ff <= din;
							lvl2_1ff <= lvl1_1ff;
						end else begin : LOWER_PLACEMENT_1
							lvl1_1ff <= lvl1_1ff;
							lvl2_1ff <= din;
						end
					end else begin
						fsm_cs <= COMP1;
					end
				end
				
				COMP2 : 
					if (vld) begin
						fsm_cs <= COMP3; 
						if (din > lvl1_1ff) begin : UPPER_PLACEMENT_3
							lvl1_1ff <= din;
							lvl2_1ff <= lvl1_1ff;
							lvl3_1ff <= lvl2_1ff;
						end else if (din > lvl2_1ff) begin : MIDDLE_PLACEMENT_1
							lvl1_1ff <= lvl1_1ff;
							lvl2_1ff <= din;
							lvl3_1ff <= lvl2_1ff;
						end else begin : LOWER_PLACEMENT_2
							lvl1_1ff <= lvl1_1ff;
							lvl2_1ff <= lvl2_1ff;
							lvl3_1ff <= din;
						end
					end else begin
						fsm_cs <= COMP2;
					end

				COMP3 : begin
					if (vld) begin
						fsm_cs <= IDLE; // return to idle, await next number
						done <= 1'b1; // assert done flag
						if (din > lvl1_1ff) begin : UPPER_PLACEMENT_4
							lvl1_1ff <= din;
							lvl2_1ff <= lvl1_1ff;
							lvl3_1ff <= lvl2_1ff;
							lvl4_1ff <= lvl3_1ff;
						end else if (din > lvl2_1ff) begin : UP_MID_PLACEMENT_1
							lvl1_1ff <= lvl1_1ff;
							lvl2_1ff <= din;
							lvl3_1ff <= lvl2_1ff;
							lvl4_1ff <= lvl3_1ff;
						end else if (din > lvl3_1ff) begin : LOW_MID_PLACEMENT_1
							lvl1_1ff <= lvl1_1ff;
							lvl2_1ff <= lvl2_1ff;
							lvl3_1ff <= din;
							lvl4_1ff <= lvl3_1ff;
						end else begin : LOWER_PLACEMENT_3
							lvl1_1ff <= lvl1_1ff;
							lvl2_1ff <= lvl2_1ff;
							lvl3_1ff <= lvl3_1ff;
							lvl4_1ff <= din;
						end
					end else begin
						fsm_cs <= COMP3;
						done <= 1'b0;
					end
				end
				
				
			endcase
		end
	end
		
	assign lvl1 = lvl1_1ff;
	assign lvl2 = lvl2_1ff; 
	assign lvl3 = lvl3_1ff; 
	assign lvl4 = lvl4_1ff; 
    
endmodule