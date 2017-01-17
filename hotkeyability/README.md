## hotkey ability
 キーボードショートカットに特性を入れることが出来る

### コマンド
 `/hotkey number ClassID`

### number
* number はキーボードに割り振られている数値
    * aは1
    * qは11
    * 1は21 となっている
* 例えばuはqの行で7個目のキーなので17となる

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
* それを削除したい場合は`/hotkey d 28`のように入力すればよい
* マップを移動した後アイコンが削除される

## コマンド
* `/hotkey list` 現在設定されているキーと特性名を表示
* `/hotkey d KeyNumber` key numberの設定を削除する
* `/hotkey KeyNumber abilityID` KeyNumberにabilityIDの特性を設定する
 