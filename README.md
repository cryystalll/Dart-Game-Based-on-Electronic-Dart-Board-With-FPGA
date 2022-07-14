<div align=center><img src="/img/d1.png" alt="Cover" width="55%"/></div>

## Introduction
* 結合fpga的飛鏢射擊遊戲
```
規則參考飛鏢遊戲的01game與輪流計分
射擊區域則以難易度分類
由中心往外分為[紅心·藍心·一倍·兩倍·三倍區]
```
* 實作出的主要規則
```
1.01game:最後射擊要使分數剛好歸零，如果射擊分數超過目前剩餘分數，則分數不變。
2.輪流射擊：雙方玩家一開始有相同初始分數，一人一回合射擊三次換下一人，最先使分數歸零的玩家獲勝。
3.倍數區域：射擊得分根據難易度分為若干區塊，擊中規定區域之內則得到該分數。
```
## System Specipication
* 1. Hardware implementation
```
(1)將電子飛鏢靶拆解，將內部的薄膜感應電路由原本的 PCB 板上解焊，並重新與
杜邦線焊接，並藉由 Pmod 接孔與 FPGA 板連接。

```
<div align=center><img src="/img/d2.png" alt="Cover" width="55%"/></div>


```
(2) 經過測試，訊號傳遞的規則如下:
飛鏢靶總共有 10*2 個扇形區塊與內、外紅心。我們透過 master 與 slave 兩個 array
判斷射中的區域。master 為 10bits output array，每個 bit 可判斷的分數區塊為兩組
扇形（其中兩個 master 與紅心控制相關），將所有的 master 設為高電位(1)，並輪
流將不同 bit 設為低電位(0)來給予 slave 變化。slave 則對應到每兩個分數區塊的子
區塊，一個區塊有三塊設有感應器（分別為一倍、兩倍、三倍區），另外加上正中
心的區塊，slave 感應的區域總共有七塊，在被 master 觸碰到時，會因為電位差
異，產生相對應的 slave array(7 bits input array)。透過實驗與測試 master 與 slave 的
對應關係，我們可以知道不同 master 值與 slave 值組合判斷飛鏢擊中之區域，再去
計算分數。

```
<div align=center><img src="/img/d3.png" alt="Cover" width="55%"/></div>

## Code Implementation
* Top Module

<div align=center><img src="/img/d4.png" alt="Cover" width="55%"/></div>

```
Top module 用於製作不同的 clock、FPGA 板上按鈕的 debounce 與 onepulse、並連
接各個 module。另外，Top module 還負責兩個 player 的轉換，在按下 switch button
後會將 player = ~player，並且 player 會與分數顯示、LED 燈號顯示、玩家分數計算
息息相關。
在 7 segment 顯示部分，會透過 segmentDisplay module 將 player score 轉為 
7 segment 顯示，並且特別在玩家分數歸零時，以 clr 表示 clear 成為勝利顯示方式，
並同時亮起 score 歸零那邊的 player LED。
```
* (2) Dartboard Module
<div align=center><img src="/img/d5.png" alt="Cover" width="55%"/></div>


```
這個 module 是負責 dartboard 感應以及分數計算。
我們將每個 player 的分數與任何操作獨立出來，因此在傳入此 module 的 input 有
player 這個 signal，並且在 top module 中會使用兩個 dartboard module，完成比較有
系統性的架構。
Dartboard module 實作中，總共有五個 state，
分別為：WAIT、CNT、HOLD、SWITCH、FINISH。
```

* (3) State Specification
<div align=center><img src="/img/d6.png" alt="Cover" width="55%"/></div>

```
WAIT state 是在等待飛鏢射出的 state，我們透過判斷 slave 有任一 bit 變為 0 時，得
知有飛鏢碰觸到標靶，並判定該鏢分數，並進入 CNT state。
CNT state 中，首先要先計算射完該鏢後的剩餘分數，如果分數歸零就會進入
FINISH state，若沒有歸零則遊戲繼續；在分數沒有歸零的情形下，我們又分為兩
個情形。根據常見的飛鏢規則，通常每個玩家可以在一輪中投擲三隻飛鏢，因此我
們使用 remain times 這個變數來判斷這名 player 還有多少次投擲機會。如果投擲機
會還有剩餘，會進入 HOLD state，並且透過 FPGA 板上的 LED 燈顯示剩餘機會；
如果三次投擲完畢，LED 燈就會全數熄滅，並且進入 SWITCH state。
HOLD state 的使用是因為 input 的 slave signal 訊號比較不穩定，如果飛鏢靶受到叫
強力的碰撞、晃動，很容易造成板子上的方塊壓到薄膜，導致連續得分。為了避免
這個情形發生，我們在每次得分後就進入 HOLD state，需要按下一顆 button 才可
以回到 WAIT state 繼續遊戲。
SWITCH state 則是三枚飛鏢全部投擲完畢後，準備進行人員更換而準備的 state。
在按下指定 button 後 Top module 會改變 player，此時的分數計算已經不再與這邊
有所相關，但會重設這名玩家的 remain times。
FINISH state 是玩家分數歸零時進入的 state，特別注意的是如果射出的分數超出剩
餘分數是不會 FINISH 的，分數會是維持原本不做改變。FINISH state 會將勝利方
的 remain times 設為 3’b111，這是因為 LED 燈號顯示是透過 remain times 判斷，為
了顯示勝方的 LED 燈特別進行此處理。
```

## Experiment Results and Presentation

<div align=center><img src="/img/d7.png" alt="Cover" width="55%"/></div>

```
1.經過實測，電子器材中的 pcb 板訊號能成功 program 至 fpga 板，兩片薄膜電路也
可以成功感測訊號，至於傳輸穩定度則取決於焊接部分的完整程度。
2.master 訊號會影響 slave 訊號，若電路跳動頻繁或在遊戲中震動到標靶內部元
件，會影響 fpga 接收到跳動指令，但事實上並無擊中該區域，因此應固定標靶，
並設置按鈕防止 fpga 多次扣分，影響遊戲體驗。
```

<div align=center><img src="/img/d8.png" alt="Cover" width="55%"/></div>

## Conclusion
```
1. Review
這次實作我們成功將 FPGA 連結至標靶，了解到硬體內部控制的機制並實做了接
線的流程，並將感應結合程式，相較於以往的程式實作，能實際做出硬體是我們最
大的收穫，過程中也遭遇了許多困難，從一開始由拆解 PCB 板焊接電路到
FPGA，甚至是還毀掉了第一塊飛鏢靶，到一步一步實驗測試 master 與 slave 薄膜
電路的關係，尤其是如何消除雜訊，提升接收訊號的準確度，是我們一直努力的方
向。
2. Future
這次比較可惜的是因為 slave 這個 input 訊號太過不穩定，尤其在 master 輪流轉換
時很難準確的判斷 slave 與 master 被接觸的組合。雖然多次嘗試 debounce slave 訊
號，也曾經參考 keyboard sample code 中 debounce 的方法，但最終都無功而返。為
了讓 demo 時有較好的遊戲呈現，我們將 master 改為固定，讓 slave 訊號較為穩
定，但就較缺乏計分的完整度，是希望以後有機會能夠改善的地方。
```




