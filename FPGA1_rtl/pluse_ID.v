`include "./param.v"
module pluse_ID(
    input                                 clk_200m                ,
    input                                 reset_200m              ,
    input      [`MVT_THRESHOLDS_1-1:0]      q_valid                 ,

    output reg [`MVT_THRESHOLDS_1-1:0]      latch                   ,
    output reg                            mvt_event_valid         
);

    parameter   [3:0] S1  =  4'b0001;
    parameter   [3:0] S2  =  4'b0010;
    parameter   [3:0] S3  =  4'b0100;
    parameter   [3:0] S4  =  4'b1000;
    
    reg   [3:0] c_state ;
    reg   [3:0] n_state ;
    reg   [4:0] Cnt     ;

/*状态机第一段*/
    always@(posedge clk_200m or negedge reset_200m)begin
      if(!reset_200m)begin
        c_state <= S1;
      end else begin
        c_state <= n_state;
      end
    end
    
/*状态机第二段*/
    always@(*)begin
      case(c_state)
        S1:begin
          if(q_valid[1] & q_valid[0])begin
            n_state = S3;
          end else begin
            if(q_valid[1])begin
              n_state = S2;
            end else begin
              n_state = S1;
            end
          end
        end
        S2:if(q_valid[0])n_state = S3;else n_state = S2;
        S3:if(Cnt==5'd20)n_state = S4;else n_state = S3;
        S4:n_state = S1;
        default: n_state = S1;
      endcase
    end
/*状态机第三段*/
    always@(posedge clk_200m or negedge reset_200m)begin
      if(!reset_200m)begin
        latch <= 'd0;
        mvt_event_valid <= 1'b0;
        Cnt   <= 'd0;
      end else begin
        case(n_state)
        S1:begin
          latch <= 'd0;
          mvt_event_valid <= 1'b0;
        end
        S2:begin
          latch <= 'd0;
          mvt_event_valid <= 1'b0;
        end
        S3:begin
          latch <= 'd0;
          Cnt   <= Cnt + 5'd1;
          mvt_event_valid <= 1'b1;
        end
        S4:begin
          latch <= {`MVT_THRESHOLDS_1{1'b1}};
          Cnt   <= 5'd0;
          mvt_event_valid <= 1'b0;
        end
        endcase
      end
    end
endmodule
