# educo_yoyaku
予約管理アプリ

## 概要
ロボット・プログラミング教室で使う予約管理アプリ(スマホ版は閲覧専用)です。

## 機能
- LINE BOTから予約を取得 → リストビューで表示
- Educo予約で予約人数を確認 → カレンダーの日付部分で人数を表示
- 生徒の引き継ぎ項目の伝達 → アカウント詳細ページで表示
- 出席確認 → Todoリストのようなチェックボックスで表示

## 経緯
ロボット・プログラミング教室では生徒の進度別にコースが分かれており、もちろん求められるサポートの手厚さも違います。同じ予約人数でも、適切なスタッフ数は変わるということが起こりうるのです。このような、汎用的な予約アプリではカバーできない用件を満たした予約アプリを作ろうと思い、educoを作っています。
他にも
- 兄弟、姉妹でも保護者の予約アカウントは一つなので予約者1人につき実際の人数が1人とは限らない。
- 授業は月に2回と決まっているので、振替残り日数や、今月後何回来るべきかも簡単に把握できるようにしたい。

## スマホアプリで、できること・できないこと
### できること
- 予約情報の閲覧
- 出席チェック
- 生徒の情報閲覧
### できないこと
- 予約枠の設定
- 教室情報の編集

## 使用技術
- Flutter 3.27.4
- データベース Firebase Firestore
- 認証システム Firebase Authentication

## 実装予定
- テスト
- 管理サイト(webアプリ)