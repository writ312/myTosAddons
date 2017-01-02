## myTosAddons

### 注意
アドオンマネージャーを入れていないと動かないものがあります

___
## 1.friend info
extend friend list contextmenu

## 1.friend info
フレンドリストから装備情報の取得が出来るようになる

___
## 2.poisonpot auto charge
1. have Bagworm Poison(wugushi master sell)
2.  poisonpot amount under 700
3.  change map or channel
4. poisonpot chaege auto


## 2.poisonpot auto charge
 ポイズンポットを自動で補充するようになる  
 ただし、補充するのは毒液からのみでタイミングはマップなどを移動した時など

___
## 3. resource manager
 フレッチャー、ティルトルビー、サッパーの矢や木などの残数を表示するフレームを追加する  
 基本はミニマップの下に表示され、色は白、残数が100以下はオレンジ、50以下は赤で表示される  
 コマンドは <br>/rscm でオンオフ<br>/rscm 1 or 2 or 3 or 4でそれぞれフレッチャー、ティルトルビー、サッパー,ルーンキャスターに切り替えることが出来る。
 ex) /rscm 1 (フレッチャーに変更)


## 4. acquisition amount of silver
* show acquisition amount of silver
* When it is lower than 10k,do not show

## 4. money diff
 1つ前のマップでいくらシルバーが手に入ったか表示するアドオン
 10k以下の場合は表示されない


___
## 5. hotkey ability
* set abilities in hotkey
* command is `/hotkey number ClassID`

### number
* Numbers allocated to the keyboard
* for example, a is 1 , q is 11 , 1 is 21

| key | number | key | number | key | number |
| :-: | :-: | :-: | :-: | :-: | :-: |
| a | 1 | q | 11 | 1 | 21 | 
| s | 2 | w | 12 | 2 | 22 |
| d | 3 | e | 13 | 3 | 23 |
| f | 4 | r | 14 | 4 | 24 |
| g | 5 | t | 15 | 5 | 25 |
| h | 6 | y | 16 | 6 | 26 |
| j | 7 | u | 17 | 7 | 27 |
| k | 8 | i | 18 | 8 | 28 |
| l | 9 | o | 19 | 9 | 29 |
| ; | 10 | p | 20 | 0 | 30 |

### ClassID
* ability's ClassID
* searce [tosgbase](https://tos.neet.tv/attributes)
  
| ability name | ClassID |  
| :-: | :-: |
|Heal: Remove Damage|　401016|  
|Hangman's Knot: Additional Damage|　205002|   
|Joint Penalty: Lightning|205007|   
|Joint Penalty: Poison|205008|
|Provoke| 101020 |  

### usage
* Heal: Remove Damage set with 8 key
* `/hotkey 28 401016`
* If remove this setting , input `/hotkey d 28`
* Icons are deleted after changing  map

## 5. hotkey ability
 キーボードショートカットに特性を入れることが出来る
 準備
 
~~1. データを[DL](https://github.com/writ312/myTosAddons/releases/download/ver0.9/ver0.9.zip)~~  
~~2. ☃hotkeyability.ipfをToSのdataフォルダの中に入れる~~  
~~3. hotkeyabilityフォルダをTosのaddonsフォルダの中に入れる~~  
~~4. もしaddonsフォルダがない場合はaddon managerをダウンロードする~~  
~~5. ToSを起動する~~  

### コマンド
 `/hotkey number ClassID`

### number
* number はキーボードに割り振られている数値
* aは1,qは11,1は21となっている
* 例えばuはqの列で7個目のキーなので17となる

| key | number | key | number | key | number |
| :-: | :-: | :-: | :-: | :-: | :-: |
| a | 1 | q | 11 | 1 | 21 | 
| s | 2 | w | 12 | 2 | 22 |
| d | 3 | e | 13 | 3 | 23 |
| f | 4 | r | 14 | 4 | 24 |
| g | 5 | t | 15 | 5 | 25 |
| h | 6 | y | 16 | 6 | 26 |
| j | 7 | u | 17 | 7 | 27 |
| k | 8 | i | 18 | 8 | 28 |
| l | 9 | o | 19 | 9 | 29 |
| ; | 10 | p | 20 | 0 | 30 |

### ClassID
* ClassIDは特性に割り振られているID
* [tosgbase](https://tos.neet.tv/attributes)などで検索する  
  
| 特性名 | ClassId |  
| :-: | :-: |
|ヒールダメージ|　401016|  
|ハング　ダメージ|　205002|   
|ジョイント 雷 |205007|   
|ジョイント 毒 |205008|
|プロヴォ| 101020 |  

* ヒールのダメージ特性を数字の8にセットしたい場合は
* `/hotkey 28 401016`と入力すればよい
* 削除したい場合は`/hotkey d 28`のように入力すればよい
* マップを移動した後アイコンが削除される

___
## その他
 バグがあればissue又はtwitterで教えてくれると助かります。