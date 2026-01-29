# 2025年度 久我セミナーレポート
情報電気工学科3年 232t3253 元田浩太郎

## 本セミナーの目的
単一サイクルパイプラインプロセッサから,5段パイプラインプロセッサへの改良を通じてプロセッサへの理解を深める.

## レポート概要
本セミナーで取り扱った内容の理解と,実装を示す. また,主観も織り交ぜてオリジナリティに溢れるものにしたい.

## レポートの流れ
セミナーでの進行におよそ合わせて以下の様に章立てした.
<!-- 1. 単一サイクルプロセッサの理解 -->
2. 5段パイプラインプロセッサの実装
3. プロセッサ性能評価
4. fpga搭載ボードのLEDに出力して動作確認
5. P命令拡張
6. 演算器の記述の差異に伴う回路評価
7. まとめ
8. 感想

<!-- ## 1. 単一パイプラインプロセッサの理解
パイプライン化する前のソースコードは以下の様なプロセッサであった.
[ここにパイプライン化前のプロセッサ図を入れる.]

このプロセッサについて補足する.
* PC(programme counter)は常に共通
* クリティカルパスは,命令フェッチからレジスタ書き込みまでの全ての処理.
* 動作周波数は, [操作周波数をここに記載] -->


## 2. 5段パイプラインプロセッサの実装

五段パイプラインプロセッサを以下のように設計した.
[ここに,5段パイプラインプロセッサ図を入れる]


これから,大きく二つの内容に分けて説明する.
1. 各命令タイプごとの制御/データパス
2. 命令タイプに依存しない実装

### 1. 各命令タイプごとの制御/データパス.

以降では,命令タイプごとに「データパス仕様」と「実装の工夫」をそれぞれ1つずつ述べる(実装は `seminor-dir/riscv-np/np_original` を参照).

* Rタイプ命令(`OP_FUNC2`: add/sub/and/or/xor/slt等 + shift)
    * データパス仕様: rs1/rs2をEXステージに入力し,ALUまたはSHIFTで演算してWBでrdへ書き戻す(メモリは通らない,`MemtoReg=00`, `ALUSrc=0`).
    * 実装の工夫: shift系(sll/srl/sra)は `shift` モジュールに分離し,`ALUorSHIFT` でALU結果とMUXすることで,演算器の責務を単純化した.

* Iタイプ命令(`OP_FUNC1`: addi/andi/ori/xori/slti + shift immediate)
    * データパス仕様: rs1と即値(符号拡張)をEXで演算し,WBでrdへ書き戻す(`ALUSrc=1`, `MemtoReg=00`). shift immediateは shamt=imm[4:0] を用いる.
    * 実装の工夫: 即値生成はFTに応じて一箇所で行い(I-typeをデフォルト),shift命令も同じ `ALUOp` 系の制御で `shift` に流せるようにした.

* Iタイプ命令(`OP_LOAD`: load系)
    * データパス仕様: EXでアドレス=rs1+immを計算し,MEMで `daligner` + `dmem` によりbyte/half/wordの読み出しと(必要なら)符号拡張を行い,WBでrdへ書き戻す(`MemtoReg=01`).
    * 実装の工夫: メモリアライン/サイズ変換を `daligner` に集約し,`MemRead`(01/10/11)と`DMSE`(符号拡張)の組だけでlb/lh/lw/lbu/lhu等を扱えるようにした.

* Sタイプ命令(`OP_STORE`: store系)
    * データパス仕様: EXでアドレス=rs1+immを計算し,MEMで `daligner` が生成するbyte enableに従って `dmem` に書き込む(`MemWrite`=01/10/11). 書き込みデータはrs2.
    * 実装の工夫: storeデータ(rs2)にもフォワーディングを適用し,`STORE_VAL_E = src2_fwd` としてMEMへ渡すことで,直前の命令結果をストール無しでストアできる場合を増やした.

* Bタイプ命令(`OP_BR`: beq/bne/blt/bge/...)
    * データパス仕様: EXで比較を行い(比較結果はALUのbit0で返す前提),成立時は分岐先PC=PC+immへ更新する. 分岐判定はEXなので,成立時はIF/IDとID/EXをflushする.
    * 実装の工夫: `isBranch_E` をそのままIFのPC更新とパイプラインflush信号に使い,分岐成立時に「後続2命令をNOP化」するだけの単純な制御で制御ハザードを処理した(未成立はそのまま順次実行). flushに関しては,簡易コード用いて以下で説明.

* Jタイプ命令(`OP_JAL`)
    * データパス仕様: EXで分岐先PC=PC+immを生成し,常に分岐する. 同時にWBでrdへPC+4を書き戻す(`MemtoReg=10`).
    * 実装の工夫: `RS1_PC` を立ててALUのA入力をPCに切り替え,PC+immの加算をALUに統一することで,専用の分岐先加算器を増やさずに実装した.

* Iタイプ命令(`OP_JALR`)
    * データパス仕様: EXで分岐先PC=`(rs1+imm) & ~1`を生成し,常に分岐する. 同時にWBでrdへPC+4を書き戻す(`MemtoReg=10`).
    * 実装の工夫: RISC-V仕様に合わせて分岐先のLSBを必ず0にするため,`{alu_val_e[31:1], 1'b0}` としてアドレスを丸める処理を入れた.

* Uタイプ命令(`OP_LUI` / `OP_AUIPC`)
    * データパス仕様: LUIはA=0としてimm(U)をそのままrdに書き戻し,AUIPCはA=PCとしてPC+imm(U)をrdに書き戻す(いずれも `ALUSrc=1`).
    * 実装の工夫: A入力の選択を `RS1_Z` / `RS1_PC` によって行い,これらが立つ場合はフォワーディングを無効化して(常に0/PCを使う),制御を簡潔にした.

### 2. 命令タイプに依存しない実装
[書きたいこと]
* フォワーディングユニット
* ハザードとstall
* 各制御信号の説明

ハザード,フォワーディングユニット,最後に各制御信号について述べたい.
まず,ハザードについてのべる. ハザードとは,次のクロックで命令を実行できない状況を指す.これには,構造ハザード,データハザード,制御ハザードのみ三つがある.構造ハザードとは,一緒に実行される命令の組み合わせにハードウェアが対応できないために発生するハザードであり,例えば,IDステージでレジスタ読み出しw,WBステージでレジスタ書き込みを行う場合,レジスタへの操作が時間的に重複してしまうため工夫なしにはハザードが発生してしまう.私のプロセッサでは,レジスタ読み出し(ID)をクロック立ち上がり時に,レジスタ書き込み(WB)をクロック立ち下がり時に行うことで,構造ハザードの回避を図った.データハザードとは,命令の実行に必要なデータがまだ利用可能になっていないために発生してしまうハザードである.これを解決するのが後述するフォワーディングである.制御ハザードとは,パイプライン処理中の分岐のために発生するハザードである.私のプロセッサの場合,分岐の判定はEXステージであるため,分岐予測(本プロセッサでは静的分岐予測を採用)が外れてしまった場合には,すでに命令が発行された後続の2命令がストールされる.これに関しては単純な静的分岐予測器ではなく,動的分岐予測器などを用いて分岐予測ヒット率を上げることで,クロックの無駄削減できるだろう.

次に,フォワーディングユニットについて.これの設計次第で,通常ならばデータハザードが発生するところを全力で駆け抜けることができるようになる.私は,以下のようにフォワーディングユニットを設計した.

以下がフォワーディングユニット.
```Verilog
    always @(*) begin
        if (RegWrite_EM && (RD_EM != 5'd0) && (RD_EM == RS1_DE))
            ForwardA = 2'b10;
        else if (RegWrite_MW && (RD_MW != 5'd0) && (RD_MW == RS1_DE))
            ForwardA = 2'b01;
        else
            ForwardA = 2'b00;
    end

    always @(*) begin
        if (RegWrite_EM && (RD_EM != 5'd0) && (RD_EM == RS2_DE))
            ForwardB = 2'b10;
        else if (RegWrite_MW && (RD_MW != 5'd0) && (RD_MW == RS2_DE))
            ForwardB = 2'b01;
        else
            ForwardB = 2'b00;
    end
```
フォワーディングユニットが二つあるのはALUへの入力が2つあるからである.それぞれのbit列の状況を自然言語で表すならば,
| フォワーディング制御信号 | ソース | 概要 | 
| - | - | - |
| ForwardA=00 | ID/EX | ALUの第一オペランドがレジスタファイルから得られる | 
| ForwardA=10 | EX/MEM | ALUの第一オペランドが1クロック前のALUの結果からフォワーディングされてくる. |
| ForwardA=01 | MEM/WB | ALUの第一オペランドが2クロック前のALUの結果からフォワーディングされてくる. |
| ForwardB=00 | ID/EX | ALUの第二オペランドがレジスタファイルから得られる | 
| ForwardB=10 | EX/MEM | ALUの第二オペランドが1クロック前のALUの結果からフォワーディングされてくる. |
| ForwardB=01 | MEM/WB | ALUの第二オペランドが2クロック前のALUの結果からフォワーディングされてくる. |

また,制御信号00に含まれているが,同じレジスタを経由してデータを渡す方法もあり,これはバイパシングであると理解している.

以下に,ハザード検知ユニットも提示しておく. ハザードが発生すると,先述したようにストールが発生し,ストールの実装も続けて示しておく.
```Verilog
`include "riscv.vh"

module hazard_detection_unit (
    input  [4:0] RS1_ID,
    input  [4:0] RS2_ID,
    input        RS1_PC_ID,
    input        RS1_Z_ID,
    input  [2:0] FT_ID,
    input  [4:0] RD_DE,
    input  [1:0] MemRead_DE,   // 00: none
    output       hazard_stall
);
    // rs1/rs2 を本当に使う命令だけを対象にする
    wire use_rs1 = ~(RS1_PC_ID | RS1_Z_ID);                 // PCやゼロを使う場合は依存なし
    wire use_rs2 = (FT_ID == `FT_R) | (FT_ID == `FT_B) | (FT_ID == `FT_S); // R,B,S は rs2 使用

    assign hazard_stall =
        (MemRead_DE != 2'b00) &&
        (RD_DE != 5'd0) &&
        ( (use_rs1 && (RD_DE == RS1_ID)) ||
          (use_rs2 && (RD_DE == RS2_ID)) );
endmodule
```
以下が,ストールの実装の一例.ストールの実装と聞いて最初は何をしたらいいのか全然わからなかったが,要はすでに流れている命令を消してしまえばいいというコンセプトをもとに,IFステージで作成される,PC, PC+4, IDATAをリセットするに至った.
```VHDL
PC_FD    <= PC_IF;
PC4_FD   <= PC4_IF;
IDATA_FD <= IDATA_IF;
```

最後に,各制御信号とその意味を以下に記載する.(P命令は後述するため,外してある.)
| 信号名 | 役割 | 
| - | - | 
| MemtoReg | 00: レジスタへ書き込みむ値がALUから得られる. 01: DMEMから得られる. 10: PC+4(jalrなどの戻りポインタ)  |
| RegWrite | 0: レジスタかきこみなし, 1: レジスタ書き込み |
| Branch | 0 : 分岐しない, 1: 分岐 |
| MemWrite | 0: メモリ書き込みなし, 1: メモリ書き込み|
| MemRead | 0: メモリ読み出しなし, 1: メモリ読み出し | 
| ALUArc | 0: ALUの第二引数がRF_DATA2, 1: ALUの第二引数がIMM_VAL_EXT |
| ALUOp |  |
| ALUorSHIFT | ALUとSHIFTのどちらの結果を用いるのか |
| DMSE |  |
| FT | 命令タイプを識別する.(IDステージで重宝). |
| RS1_PC | Uタイプ命令(auipc命令)を識別 |
| RS1_Z | Uタイプ命令(lui命令)を識別 |



## 3. プロセッサ性能評価

本章は以下の3点にまとめる.

### 3.1 周波数の結果
FPGA上での動作確認では,本プロセッサは75MHzで動作した.一方,100MHzではタイミングを満たさず,同じ構成のままでは安定動作しなかった.

### 3.2 高速化のために実施した工夫(実装)
高速化(および制御の単純化)のため,分岐はEXステージで確定させ,EXからIFへ `isBranch_E` と分岐先PC(`PC_IMM_E`)を直接フィードバックしている.これにより,分岐成立時は次サイクルから正しいPCで命令フェッチを再開できる.

また,分岐成立時に誤って先行フェッチ/デコードされた命令を消すため,パイプラインレジスタのflush信号(`flush_FD`,`flush_DE`)を `isBranch_E` に接続し,IF/IDおよびID/EXをNOP化する構成にした.この方式は追加の状態機械を要さず実装が単純である.

### 3.3 今後の高速化案
今後さらに高速化するには,次の2方向が有効だと考える.

- 分岐予測を動的にして,分岐成立時のflush頻度(=無駄サイクル)を減らす.
- EXステージで直列に並ぶMUX/演算(オペランド選択,フォワーディング選択,即値/レジスタ選択など)を可能な範囲でID側へ前倒しし,EX→IFフィードバックを含むクリティカルパスを短縮する(分岐ターゲットの事前計算や,分岐判定に必要な比較の前倒しがあげられる.).


## 4. fpga搭載ボードのLEDに出力して動作確認
以下の三つの内容に分けて説明する.
1. プロセッサと外部I/Oの接続, レイヤーの整理.
2. トップモジュールの作成
3. 制約条件ファイル(.xdc)の作成

### 1. プロセッサと外部I/Oの接続,レイヤーの整理.


大まかなレイヤーは上記に示す通りである. 外部とのI/Oがはっきりしたことと,前章まで用いていたプロセッサモジュールが,riscvと,riscv_coreに分割されていることがわかる.
上記の図で登場しているriscvとは,プロセッサのトップモジュールとして扱い,プロセッサ外のモジュールとのI/Oを管理している.一方でriscv_coreでは,完全にプロセッサの本体が定められており,前章までで扱っていたプロセッサに該当する.
ボード上からプロセッサのトップモジュール(riscv)へのimputはCLKとRSTNの二つのみである.私が作成したプロセッサ(riscv_core)は,100MHzに間に合わなかったが,75MHzでは動作確認できたので,ボードから入ってきたCLKは,clk_wiz_0というモジュール(vivadoで事前に生成した)を通して75Mhzに周波数を落としている. これを,riscv_coreに入力する.
また,dmemがプロセッサから分離している点にも注目したい.

### 2. トップモジュールの作成
トップモジュールの一部を以下に示す.
```verilog
module riscv #(
   parameter DMEM_BASE = 32'h0010_0000,
   parameter DMEM_SIZE = 32768,
   parameter DMEM_FILE = "data.mif",
   parameter LED_BASE  = 32'h0012_0000  // 0x0011_FFFF より上
)(
   input  wire        CLK, // 100MHzで入ってくる想定
   input  wire        RSTN_IN,
   output wire [15:0] LED   
);
   wire CLK75;
   wire LOCKED;
   // 100MHz -> 75MHz に,周波数を落とす
   clk_wiz_0 clk_wiz_inst (
       .clk_in1( CLK ),
       .clk_out1( CLK75 ),
       .reset( ~RSTN_IN ),
       .locked(LOCKED)
   );


   assign RSTN    = RSTN_IN & LOCKED;
   wire RST = ~RSTN;
```
最初に,parameterの指定がされている.
利用したメモリは,アドレスに応じてinstruction memoryとdata memoryの二つに分割されている. 
具体的には,アドレス32’h0000_0000 ~ 32’h000F_FFFFがinstruction memoryであり,32’h0010_0000 ~ 32’h0011_FFFFがdata memoryである.LEDのために,新しくメモリを確保する必要があるが,instaruction memoryとdata memoryを侵害しないように気をつけなければならない. コード中で,LED_BASEを32’h0012_0000としているのは,そのためである.
LOCKEDとは,[todoの説明]

### 3. 制約条件ファイル(.xdcの作成)

以下に,fpgaボードの仕様書から得た,ピンと制御信号の対応を以下に示す.
| riscv | board |
| ---- | ---- |
| E3 | clk | 
| C12 | rst |
| H17 | LD0 | 
| K15 | LD1 |
| J13 | LD2 | 
| N14 | LD3 | 
| R18 | LD4 | 
| V17 | LD5 | 
| U17 | LD6 | 
| U16 | LD7 | 
| V16 | LD8 | 
| T15 | LD9 | 
| U14 | LD10 | 
| T16 | LD11 | 
| V15 | LD12 | 
| V14 | LD13 | 
| V12 | LD14 | 
| V 11 | LD15 | 

上記の仕様を元に,制約条件ファイルを作成した.
```xdc
## Configuration options
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Clock signal
# 100 MHz clock
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK}];

## Reset
set_property -dict { PACKAGE_PIN C12   IOSTANDARD LVCMOS33 } [get_ports { RSTN }];

## LEDs
# Mapping WB_RD_VAL[0:15] to LD0-LD15
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { LED[0] }];  # LD0
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { LED[1] }];  # LD1
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { LED[2] }];  # LD2
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { LED[3] }];  # LD3
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { LED[4] }];  # LD4
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { LED[5] }];  # LD5
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { LED[6] }];  # LD6
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { LED[7] }];  # LD7
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { LED[8] }];  # LD8
set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { LED[9] }];  # LD9
set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { LED[10] }]; # LD10
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { LED[11] }]; # LD11
set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { LED[12] }]; # LD12
set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS33 } [get_ports { LED[13] }]; # LD13
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { LED[14] }]; # LD14
set_property -dict { PACKAGE_PIN V11   IOSTANDARD LVCMOS33 } [get_ports { LED[15] }]; # LD15
```
制約条件ファイルには,大きく分けて二つの役割があると感じている.
一つ目は,クロック制約を設けることである. 外部から,プロセッサに入ってくるクロックの周波数を,ボード側で定義している. riscvは100MHzでクロックを受けて,75MHzに落としてriscv_coreに落とす構成なので,以下のように定義して,所望の動作を得られるようにしている,
```VHDL
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports {CLK}];
```



## 5. P命令拡張
以下の二つの内容に分けて説明する.
1. P命令の特長,目的.
2. 実装.

### 1. P命令の特長,目的
SIMD命令は1つの命令で複数データを同時に処理する命令であり,32bitレジスタを複数の小さなデータに分割して独立に演算する.本レポートで扱うP命令は,32bitを

- byte(8bit)×4つの加減算器
- halfword(16bit)×2つの加減算器

として扱い,各レーンごとに加算/減算を行う(レーン間のキャリーは伝播しない).例えばPADD.Bは各8bitごとに `t2[i] = t0[i]+t1[i]` を計算し,オーバーフローは次の加減算器へ渡さずに切り捨てるため,「4個の8bit加算を並列に行う」意味になる. 以下が,参考の図である.

このようなパック演算は,同じスループットをより少ない命令数で達成できる.その結果,ベクトル命令が重くて動かないようなエッジでの処理でも,実行効率の改善が期待できる.
### 2. 実装.
今回,私が実装したP命令は以下の4種類である.
| 命令名| 内容 | P[1:0] | 
| - | - | - |
| PADD.B | 8bitずつに分割して加算する命令 | 10 | 
| PSUB.B | 8bitずつに分割して減算する命令 | 10 | 
| PADD.H | 16bitずつに分割して加算する命令 | 00 |
| PSUB.H | 16bitずつに分割して減算する命令 | 00 |

#### 命令エンコード(最小限)
P命令は独自opcode `OP_PACK` を割り当てており,命令語の一部ビットで「演算種別(add/sub)」と「パックサイズ」を指定する.

- opcode: `IR[6:0] = 7'b0111011` (`OP_PACK`)
- pack size: `IR[26:25]` (`IR_PACK_SIZE`)
- add/sub: `IR[30:27]` (`IR_ADD_OR_SUB`) で `0000:add`, `1000:sub`

#### デコードとデータパス(どこをどう流すか)
`id_stage.v` では `OP_PACK` を検出すると,基本的にはR-typeと同様にrs1/rs2を演算してrdへ書き戻す設定にする(メモリは使わない).

- `FT_ID = FT_P`
- `RegWrite_ID = 1`
- `ALUSrc_ID = 0` (B入力はrs2)
- `ALUOp_ID = IADD` または `ISUB`
- 追加信号 `PACK_SIZE_ID = IR_PACK_SIZE`

この `PACK_SIZE_ID` はパイプラインレジスタで `PACK_SIZE_DE` としてEXまで運ばれ,EXステージでALUにそのまま渡される(`ex_stage.v` の `alu_inst(.P(PACK_SIZE_DE))`).

#### ALU(加減算器間キャリーを切る実装)
P命令の本質は「加減算器間キャリーを伝播させない加減算」である.そのためALU内の加算器を,32bitを8bit×4に分割したリップルキャリー加算器として実装し,パックサイズに応じてキャリーの接続を切る.

`alu.v` では `P` に応じて `link_en[3:0]` を設定している.(次章で性能差について言及する)

- byte(`P=2'b10`): `link_en=4'b1000` とし,byte0→1,1→2,2→3 のキャリー連結を全て切る
- halfword(`P=2'b00`): `link_en=4'b1101` とし,下位16bitと上位16bitの間だけキャリーを切る
- word(`P=2'b11` または `01`): `link_en=4'b1111` とし,通常の32bit加算として動作(01がデフォルトのパックなし演算で,11は,32bitでパックする演算.今回は実装していないため同じ挙動になっている.)

各8bit加算の次キャリーは,`link_en` が1なら本当のcarry-outを次段へ渡し,0なら「新しいレーンのcarry-in」として `is_sub` を入れ直す(減算時は2の補数のため `cin=1` が必要).

また,パック時(8/16bit)は32bit全体のオーバーフロー判定が意味を持ちにくいので,`overflowFlag` はword時のみ有効化している.

新しく追加した制御信号 `P[1:0]` は,このように「どこでキャリーを切るか」を指定するために導入した.

## 6. link_en長ごとの性能を動作周波数と回路規模で比較
本章では,「レーン間キャリーの接続/切断」を指定する `link_en` の記述方法を変えたときに,合成結果がどの程度変わるかを検証する.
すでに前章で `link_en` の役割やALU内部での使い方は述べたため,ここでは実装の説明は最小限にし,以下2つの観点で比較する.

- 回路規模: VivadoのResource/Utilization Reportを参照
- タイミング: Timing SummaryのWNS(どれくらいセットアップに余裕があるか)

評価は2段階に分けた.

1. ALU単体をFPGAに載せた場合の評価(演算器の差分が直接見える)
2. プロセッサ全体をFPGAに載せた場合の評価(プロセッサ全体の中で差分がどう見えるか)

### 1. 評価対象と評価条件
比較する設計は,`link_en` の作り方が異なる次の3種類である.

- original: P命令拡張なし(比較用のベースライン)
- 1bit: carry接続を1bit刻みで制御する(分岐が32回になる実装)
- 8bit: carry接続を8bit境界だけで制御する(分岐が4回になる実装)

`link_en` (実装差分のイメージ)を再掲する.

```Verilog
   assign link_en = (P == 2'b10) ? 32'hFF7F7F7F : // byte: cut at bits 7,15,23
                    (P == 2'b00) ? 32'hFFFF7FFF : // halfword: cut at bit 15
                                     32'hFFFFFFFF; // word (11 or 01): no cut
```

```Verilog
   assign link_en = (P == 2'b10) ? 4'b1000 : // byte: cut all inter-byte carries
                    (P == 2'b00) ? 4'b1101 : // halfword: cut between lower and upper half
                                     4'b1111; // word (11 or 01): no cut
```

タイミングは100MHz(周期10ns)を制約として与え,Timing Summaryに出力されるWNSを比較した.
また,WNSから「最悪パス遅延 $D$」と「最大動作周波数の目安 $f_{max}$」を以下で概算した.

- $D \approx 10\text{ns} - \text{WNS}$
- $f_{max} \approx 1/D$

### 2. ALUのみでの性能比較
まずALU単体での結果を示す.

#### (1) 回路規模(Utilization)
主要なセル数をまとめる(LEDやI/Oの都合でIBUF/OBUF等が入るが,比較は相対差を見る).

| 指標 | original | 1bit | 8bit |
| - | -: | -: | -: |
| CARRY4 | 9 | 0 | 12 |
| LUT2 | 0 | 3 | 1 |
| LUT3 | 0 | 5 | 1 |
| LUT4 | 40 | 15 | 12 |
| LUT5 | 5 | 9 | 9 |
| LUT6 | 69 | 79 | 97 |
| LUT合計(LUT2〜6) | 114 | 111 | 120 |
| FF(FDRE) | 101 | 103 | 103 |

LUT合計だけを見ると,ALU単体では `1bit` が最小になった.
一方で `CARRY4` が `1bit` だけ0になっており,ツールが高速なキャリー・チェインを使わずにLUTで加算を組んだことが示唆される.

#### (2) タイミング(WNS)

| 指標 | original | 1bit | 8bit |
| - | -: | -: | -: |
| WNS (ns) | 3.093 | 0.241 | 0.265 |
| 最悪遅延 $D$ (ns) | 6.907 | 9.759 | 9.735 |
| $f_{max}$目安 (MHz) | 144.8 | 102.5 | 102.7 |

ALU単体では,`1bit` と `8bit` はいずれもWNSがほぼ0.2ns台で,100MHz制約は満たすが余裕は小さい.
一方,originalはWNSが約3nsあり,最大周波数の目安も高い.

この結果から「分岐回数を減らす(8bit化)と速くなる」という単純な関係ではなく,`link_en` を介した条件付きのcarry接続が,加算器の最適化(特にキャリー・チェイン推論)を阻害しやすいことが読み取れる.

### 3. プロセッサ全体での性能比較
次に,プロセッサ全体に組み込んだ場合の結果を示す.

#### (1) 回路規模(Utilization)
プロセッサ全体では,命令/データメモリのRAM系プリミティブや大規模なMUXが支配的であり,ALUの差分は相対的に小さい.
それでも差分が出ている部分(主にLUTとCARRY4)をまとめる.

| 指標 | original | 1bit | 8bit |
| - | -: | -: | -: |
| CARRY4 | 25 | 16 | 28 |
| LUT1 | 4 | 3 | 3 |
| LUT2 | 303 | 348 | 306 |
| LUT3 | 66 | 56 | 65 |
| LUT4 | 212 | 181 | 209 |
| LUT5 | 245 | 268 | 249 |
| LUT6 | 1929 | 1959 | 1929 |
| LUT合計(LUT1〜6) | 2759 | 2815 | 2761 |
| FF(FDCE) | 528 | 530 | 529 |

プロセッサ全体では,`1bit` がLUT合計で最も大きくなった(約2%増).
ALU単体のときと逆転している点が重要である.

#### (2) タイミング(WNS)

| 指標 | original | 1bit | 8bit |
| - | -: | -: | -: |
| WNS (ns) | 3.753 | 0.931 | 0.561 |
| 最悪遅延 $D$ (ns) | 6.247 | 9.069 | 9.439 |
| $f_{max}$目安 (MHz) | 160.1 | 110.2 | 105.9 |

プロセッサ全体では,`1bit` の方が `8bit` よりWNSが大きく,タイミング余裕がある.
一方でoriginalはさらに余裕が大きい.

### 4. 考察(なぜ結果が逆転するのか)
本評価で面白いのは,

- ALU単体では `1bit` が「面積(LUT合計)が小さく,ただしキャリー・チェインが使われず遅い」
- プロセッサ全体では `1bit` が「面積が少し大きいが,8bitよりタイミングに余裕がある」

というように,観点によって評価が変わった点である.

原因としては,主に次の2点が考えられる.

1. 合成/配置配線の最適化は周辺回路込みで決まる
    - ALU単体では最適化の自由度が高く,ツールがキャリー・チェインを捨ててでもLUTでまとめた方が全体最適になるケースがある(その結果,CARRY4が0になりやすい).
    - プロセッサ全体では,クリティカルパスがALU内部だけでなく,前段のMUX/フォワーディングや後段のレジスタ等を含む長いパスになりやすい.そのため,同じALU差分でも,ツールが選ぶ実装(どこをどう配置するか/どこを優先して高速化するか)が変わり,面積・WNSの関係が逆転しうる.

2. 条件付きcarry接続は「加算器」としての推論を崩しやすい
    - `link_en` を介した条件分岐は,RTL上は「carryを次段へ渡す/渡さない」のMUXを大量に挿入する形になる.
    - これが,ツールにとっては通常の `A+B` よりも扱いづらく,結果的にLUT増やクリティカルパス増に繋がる.
    - 一方で,周辺回路との兼ね合い次第では,単純な構造の方が配置配線がうまくいき,結果としてWNSが改善する場合もある.

まとめると,「自分が最適化したつもりのRTL(8bit刻み)が常に最適になる」とは限らず,設計全体の文脈(周辺のMUXやメモリ,パイプライン段の境界)に応じて,ツールの最適化結果が変わり得ることが分かった.
今回の結果では,プロセッサ全体のWNSだけを見ると `1bit > 8bit` となっており,必ずしも分岐回数が少ない記述が有利ではなかった.

## 7. まとめ


## 8. 感想
セミナーを通して,プロセッサの設計と性能評価について包括的で深い学びを得ることができた.セミナー前に実施された工学実験では,2段のパイプラインさえも作ることができずプロセッサの仕組みを全く理解していないと自覚していた.ふわっとした興味を抱えて参加したセミナーの初日から,勉強,パイプライン図の作成,実装に没頭する日々が続いて,低レイヤーに向ける興味がメキメキと根を張り出しているのを心地よく感じながら進めた.コーディングしているときに,際立って魅力的な部分が二つあったので,これ示す.一つ目は,外部モジュールに頼らない点である.高水準言語を用いた開発を行うとき,インストラクションメモリやデータメモリ,アライナー,レジスタなどは完全に隠れており,ブラックボックスであるのに対し,VHDLで書くプロセッサは,メモリのベースアドレスの指定から書き込み,読み出しまで漏らすことなく定義する必要があった.メモリというのも配列の様な構造体であるので,5段パイプラインプロセッサを,手元にある知識のみで積み上げていく満足感を感じていた.

