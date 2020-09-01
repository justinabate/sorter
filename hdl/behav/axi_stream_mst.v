`timescale 1 ns / 1 ps

// valid DATA_WIDTH  values are 64 and 32
// valid SIZE_WIDTH values are  3 and  2, respectively
module axi_stream_mst #	(
    parameter integer            DATA_WIDTH = 64)(                               
    // ctrl
    input  wire                  clk,
    input  wire                  rst, // active lo
    input  wire                  stream_trig,
    // axi stream i/f            
    output wire                  vld,
    output wire                  sof,
    output wire                  eof,
    output wire [DATA_WIDTH-1:0] dout
);

	////////////////////////////////////////////////////////////////////////////////////

    function integer num_bits (input integer int);                                   
        begin                                                                              
            for (num_bits=0; int>0; num_bits=num_bits+1) begin                                     
                int = int >> 1; // e.g. int = d8 = 4'b1000, right-shift until 0  
            end                                                  
        end                                                                                
    endfunction                                                                             

    // FIFO
	localparam                   FIFO_DEPTH = 4; // int num of axi stream transfers                                              
    localparam                   FIFO_DBITS = num_bits(FIFO_DEPTH); // num bits to reach fifo depth                                
	wire [DATA_WIDTH-1:0]        streamdata [16-1 : 0]; // 2D array
	reg  [DATA_WIDTH-1:0] 	     fifo_rdata; // fifo data stream out
	wire  	                     fifo_rdena; // fifo read enable

	// AXI STREAM
    wire  	                     axis_vld;     // valid gate
	reg  	                     axis_vld_1ff; // 1st clk dly; out wire alignment
	reg  	                     axis_vld_2ff; // 2nd clk dly
	reg  	                     axis_vld_3ff; // 3rd; ack counter pulldown
	wire  	                     axis_sof;     // sof stream word
	reg  	                     axis_sof_1ff; // 1st clk dly; out wire alignment
	reg  	                     axis_sof_2ff; // 2nd clk dly
	wire  	                     axis_eof;     // eof stream word
	reg  	                     axis_eof_1ff; // 1st clk dly; out wire alignment
	reg  	                     axis_eof_2ff; // 2nd clk dly
	reg  	                     axis_eof_3ff; // 3rd; ack counter pulldown
	reg  [FIFO_DBITS-1:0]        axis_wrcnt;     // fifo read count index
	reg  [FIFO_DBITS-1:0]        axis_wrcnt_1ff; // 1 clk dly
	reg  [FIFO_DBITS-1:0]        axis_wrcnt_2ff; // 2 clk dly
    
	// stream trigger
	reg [1:0] 					 trig_count;
    
    // FSM states
	reg        [2:0] fsm_cs;   
    localparam [2:0] IDLE = 3'b001;
	localparam [2:0] WAIT = 3'b010;
	localparam [2:0] SEND = 3'b100;    

	////////////////////////////////////////////////////////////////////////////////////	

    always @ (posedge clk) begin : CTRL_FSM                                                                    
        if (!rst) begin                                                                  
            fsm_cs <= IDLE;
			trig_count <= 2'b0;
        end else begin                                                                   
            case (fsm_cs)                                                 
                IDLE : begin                                                                                                         
                    if ( stream_trig == 1'b1 ) begin                                                           
                        fsm_cs  <= SEND;
						trig_count <= trig_count + 1;
					end else begin
						fsm_cs  <= WAIT;
					end
				end
				
                WAIT : begin
                    if ( stream_trig == 1'b1 ) begin                                                           
                        fsm_cs  <= SEND;
						trig_count <= trig_count + 1;						
                    end else begin                                                           
                        fsm_cs  <= WAIT;                              
                    end   
                end    
				
                SEND :                                                                                  					
                    if ( stream_trig ) begin                                                           
                        fsm_cs     <= SEND;
						trig_count <= trig_count + 1;						
                    end else if (axis_eof) begin                                                           
                        fsm_cs <= IDLE;                                       
                    end else begin                                                           
                        fsm_cs <= SEND; // read FIFO until transfer done                                
                    end  					
					
            endcase  
        end
    end           
    
    always @ (posedge clk) begin : FIFO_READ                                            
        if(!rst) begin                                        
            fifo_rdata <= {(DATA_WIDTH){1'b0}};                      
        end else begin
		
            if (fifo_rdena && trig_count == 2'b01) begin                                       
                fifo_rdata <= streamdata[axis_wrcnt];   
            end

            if (fifo_rdena && trig_count == 2'b10) begin                                     
                fifo_rdata <= streamdata[axis_wrcnt+FIFO_DEPTH*1];   
            end	

            if (fifo_rdena && trig_count == 2'b11) begin                                     
                fifo_rdata <= streamdata[axis_wrcnt+FIFO_DEPTH*2];   
            end			
			
            if (axis_eof_1ff) begin : PULLDOWN                                        
                fifo_rdata <= {(DATA_WIDTH){1'b0}};   
            end
        end
    end 
    
    always @ (posedge clk) begin : INDEXER                                                                            
        if(!rst) begin                                                                        
            axis_wrcnt   <= {(FIFO_DBITS){1'b0}};
        end else begin
        
			if (axis_wrcnt <= FIFO_DEPTH-1) begin : WRCNT_AND_SIZE                                                                   
                if (fifo_rdena) begin : STREAM_COUNT  
                    axis_wrcnt <= axis_wrcnt + 1;  
                end 
            end
            
            if (axis_eof_1ff && axis_vld_1ff) begin : WRCNT_RST
                axis_wrcnt <= {(FIFO_DBITS){1'b0}};
            end
            
        end
    end // done after FIFO_DEPTH # of stream transfers                                                                                                                           

    always @ (posedge clk) begin : DELAY_PROC                                                                                         
        if (!rst) begin                                                                                      
            axis_vld_1ff <= 1'b0;                                                               
            axis_vld_2ff <= 1'b0;                                                               
            axis_vld_3ff <= 1'b0;                                                               
            axis_sof_1ff <= 1'b0;
            axis_sof_2ff <= 1'b0;
            axis_eof_1ff <= 1'b0;                                                                
            axis_eof_2ff <= 1'b0;
            axis_eof_3ff <= 1'b0;
            axis_wrcnt_1ff <= {(FIFO_DBITS){1'b0}};           
            axis_wrcnt_2ff <= {(FIFO_DBITS){1'b0}};           
        end else begin                                                                                      
            axis_vld_1ff   <= axis_vld;     // 1st clk dly; align for output wires
            axis_sof_1ff   <= axis_sof;     // 1st clk dly; align for output wires
            axis_eof_1ff   <= axis_eof;     // 1st clk dly; align for output wires 
            axis_wrcnt_1ff <= axis_wrcnt;
            axis_vld_2ff   <= axis_vld_1ff; // 2nd clk dly; align for counters
            axis_sof_2ff   <= axis_sof_1ff; // 2nd clk dly; align for counters
            axis_eof_2ff   <= axis_eof_1ff; // 2nd clk dly; align for counters                                                        
            axis_wrcnt_2ff <= axis_wrcnt_1ff;
            axis_vld_3ff   <= axis_vld_2ff;
            axis_eof_3ff   <= axis_eof_2ff;
        end                                                                                        
    end // 1FF dly to align ctrl signals with dout                                                                                            

	assign fifo_rdena = axis_vld; // only read if slave rdy, don't inhibit vld     
    assign axis_vld   = ( ( fsm_cs == SEND ) && ( axis_wrcnt < FIFO_DEPTH ) ); 	    
    assign axis_sof   = ( ( fsm_cs == SEND ) && ( axis_wrcnt <=  1) ); 	    
    assign axis_eof   = ( axis_wrcnt == FIFO_DEPTH-1 ); 
	assign dout	      = fifo_rdata;   // stream to parallel bus
	assign vld        = axis_vld_1ff; // see DELAY_PROC	    
//	assign sof	      = axis_sof_1ff; // see DELAY_PROC
	assign sof	      = (axis_wrcnt == 1) ? 1'b1 :
											1'b0 ;
	assign eof	      = axis_eof_1ff; // see DELAY_PROC

    // axi 64 - streamdata - reg based
    // number of bus writes is determined by FIFO_DEPTH
	
	// STREAM 1
    assign streamdata[0]  = 64'h0002_3332_3141_0004;
    assign streamdata[1]  = 64'hFFFF_FF35_000F_0040;
    assign streamdata[2]  = 64'hFFFF_FFFF_FFFF_0002;
    assign streamdata[3]  = 64'h3035_4100_04FF_FFFF;
	// STREAM 2
    assign streamdata[4]  = 64'h0000_0000_0000_0033;
    assign streamdata[5]  = 64'hDABB_DABB_DA43_FFAB;
    assign streamdata[6]  = 64'h999A_999A_999A_9213;
    assign streamdata[7]  = 64'hA1C1_D191_A1C1_0101;
	// STREAM 3
    assign streamdata[8]  = 64'hBAD4_BADF_BAD4_29FA;
    assign streamdata[9]  = 64'h1234_5678_1234_5678;
	assign streamdata[10] = 64'h9ABC_DEF0_9A42_000F;
	assign streamdata[11] = 64'hADAD_ADAD_ADAD_ADAD;
	// STREAM 4
	assign streamdata[12] = 64'h4100_02FF_4100_02FE;
	assign streamdata[13] = 64'hDABB_DABB_4900_059A;
	assign streamdata[14] = 64'h0007_AB4A_0843_0004;
	assign streamdata[15] = 64'hFFC1_D191_A1C1_D142;
    
	
endmodule
