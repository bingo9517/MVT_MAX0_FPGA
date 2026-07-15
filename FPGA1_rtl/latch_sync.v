module  latch_sync(
    input                     clk_200m              ,
    input                     reset_200m            ,
    input                     dataout_valid_p       ,
    input       [31:0]        dataout_p             ,
    input                     dataout_valid_n       ,
    input       [31:0]        dataout_n             ,

    output  reg               sync_dataout_valid_p  ,
    output  reg [31:0]        sync_dataout_p        ,
    output  reg               sync_dataout_valid_n  ,
    output  reg [31:0]        sync_dataout_n        
);

    parameter S1  = 4'b0001;
    parameter S2  = 4'b0010;
    parameter S3  = 4'b0100;
    parameter S4  = 4'b1000;
    
    reg [3:0] next_state    ;
    reg [3:0] current_state ;

/*状态机第一段*/
    always@(posedge clk_200m or negedge reset_200m)begin
      if(!reset_200m)begin
        current_state <= S1;
      end else begin
        current_state <= next_state;
      end
    end
    
/*状态机第二段*/
    always@(*)begin
      case(current_state)
        S1: if(dataout_valid_p) next_state = S2; else next_state = S1;
        S2: if(dataout_valid_n) next_state = S4; else next_state = S3;
        S3: if(dataout_valid_n) next_state = S4; else next_state = S3;
        S4: /*if(dataout_valid_p) next_state = S2; else*/ next_state = S1;
        default: next_state = S1;
      endcase
    end
    
/*状态机第三段*/
    always@(posedge clk_200m or negedge reset_200m)begin
      if(!reset_200m)begin
        sync_dataout_p        <= 32'd0            ;
        sync_dataout_n        <= 32'd0            ;
        sync_dataout_valid_p  <= 1'b0             ;
        sync_dataout_valid_n  <= 1'b0             ;
      end else begin
        case(next_state)
          S1:begin
            sync_dataout_p        <= 32'd0            ;
            sync_dataout_n        <= 32'd0            ;
            sync_dataout_valid_p  <= 1'b0             ;
            sync_dataout_valid_n  <= 1'b0             ;
          end
          S2:begin
            sync_dataout_p        <= dataout_p        ;
            sync_dataout_n        <= 32'd0            ;
            sync_dataout_valid_p  <= 1'b0             ;
            sync_dataout_valid_n  <= 1'b0             ;
          end         
          S3:begin          
            sync_dataout_p        <= sync_dataout_p   ;
            sync_dataout_n        <= 32'd0            ;
            sync_dataout_valid_p  <= 1'b0             ;
            sync_dataout_valid_n  <= 1'b0             ;
          end 
          S4:begin
            sync_dataout_p        <= sync_dataout_p   ;
            sync_dataout_n        <= dataout_n        ;
            sync_dataout_valid_p  <= 1'b1             ;
            sync_dataout_valid_n  <= 1'b1             ;
          end
        endcase
      end
    end
endmodule