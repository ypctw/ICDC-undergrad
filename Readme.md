# IC Contest
## IC 2019-I(大學部) 
- `CONV.v`
### 注意：
- 要將 `dat_univ` 資料夾向上層移動
### 困難點
- 難點(1)：`小數點乘法`
  - 解決方式：(~target+1)將質先轉乘正數，乘完之後再去變號
- 難點(2)：`小數點進位`
  - 解決方式：直接位數延長，看小數點後第16位為一還是0
- 難點(3)：`面積`
  - 解決方式：共用乘法器，用assign!
- 難點(4)：`initial`不要用
  - 直接放在reset裡面！

## IC 2020-I(大學部) with [name=葉承軒]
### Area : `20625`
- compile_ultra `18800`
### Viewpoint
- 使用 `combinational Circuit`
```Verilog
always @(*) 
begin
    is_D = 0;
    is_H = 0;
    if (str_idx == pat_max) is_H = 1;
    else if (string[str_idx - pat_max - 1] == Space) is_H = 1;
    else is_H = 0;
        
    if (str_idx == str_max) is_D = 1;
    else if (string[str_idx + 1] == Space) is_D = 1;
    else is_D = 0;
end
```
- 將Finite State Machine放到不同Always中
### 難點：
- 難點(1)：`RTL Simulation 成功` BUT `Gate-Level Simulation 失敗`
  - 如果將cycle條大還是沒用，那代表電路設計有問題
- 難點(2)：`combinational Circuit` (不要被`Sequential Circuit` 給綁著)