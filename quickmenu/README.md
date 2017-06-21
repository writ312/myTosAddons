#Quick Menu
## command 
1. `/qm open` : UIを開く
1. `/qm [number] [titleText] [msgText]`：指定ナンバーのテキストとメッセージを変更する 
1. `/qm title  [number]　[titleText]`：指定ナンバーのタイトルを変更する 
1. `/qm msg  [number]　[msgText]`： 指定ナンバーのメッセージを変更する
1. `/qm interval [number]` ：入力後の非受付時間の設定。デフォルトは５。遅延が気になる場合は下げてください  
インターバル以外の数字はボタンの配置です。ボタンの配置は以下のとおりです。

```
1 7
2 8
3 9
4 10
5 11
6 12
```

## 使い方
このアドオンではデフォルトではF10に設定されているヘルプを開く機能を殺し、このアドオンを表示する関数に変えています  
F10以外のボタンに設定したい場合は、システムの設定からヘルプ表示の部分を好みのボタンに設定して下さい  
パッドの場合はHotkeyAbilityForJoyなどの関数で/qm openを設定するか、ToSインストールフォルダのReleaseにある`hotkey_joystick.xml`を編集し、好みのボタンの`DownScp`の中身をを`UI_TOGGLE_HELPLIST`に書き換えてください  
おすすめは３５行目のWeponSwapです。
`

