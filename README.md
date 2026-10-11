# Chirin

イベントの呼び鈴が鳴ったら、後続処理へ。

Rails.event と Active Job・Action Mailer をつなぐ、小さなEDAのコンセプト実装。
Kaigi on Rails 2026「Event is what happens」の説明を、動くコードで確かめるために育てる。

## 最初の縦切り

```ruby
class OrderReceiptJob < ApplicationJob
  include Chirin::SubscribableJob

  def perform(payload)
    order = Order.find(payload.fetch(:order_id))
    # 注文からたどれる受付時点の宛先へ、受付メールを送る。
  end
end

subscriber = OrderReceiptJob.subscribe("order.placed")
Rails.event.notify("order.placed", order_id: order.id)

# 購読の所有者が解除する。再登録前にも必要。
Rails.event.unsubscribe(subscriber)
```

これはAPIの最小例。登録の自動化やRailsのリロード対応はまだ実装していない。
繰り返しsubscribeすると重複登録になる。プロダクション導入用の完成品ではない。

イベントクラスも購読できる。`subscribe(Events::OrderPlaced)` はイベント名とクラス名の完全一致で判定する。
サブクラスは自動では購読しない。匿名クラスは指定できない。
購読フィルタにはnameだけが渡るRails mainの仕様にも対応する。
ジョブに渡すのはSERのevent Hash全体ではなくpayload。
独自イベントオブジェクトはActive Jobのserializerを別途用意する必要がある。
テストにシリアライズ・復元・実行の最小例がある。
オブジェクト形式でnotifyした場合のSERのnameはクラス名であり、文字列のorder.placedとは異なる。

購読者の呼び出しとジョブ投入は同期で行う。実行が非同期になるかはキューアダプターによる。
例外処理はEventReporterとActive Jobの設定に従う。通知の永続化・配送保証は追加しない。

## Mailerの購読

```ruby
class OrderMailer < ApplicationMailer
  include Chirin::SubscribableMailer

  def placed(event)
    order = event.order
    mail(to: order.receipt_email, subject: "ご注文を受け付けました")
  end
end

subscriber = OrderMailer.subscribe(:placed, Events::OrderPlaced)
Rails.event.notify(Events::OrderPlaced.new(order: order))
# 必要になったら Rails.event.unsubscribe(subscriber)
```

Mailerアクションにpayloadを引数一つとして渡し、`deliver_later`で投入する。
Action Mailerはアプリ側で導入する。独自イベントにはJobと同じくActive Job serializerが必要。
文字列・Symbolのイベント名も指定でき、その場合の引数はpayload Hashになる。
登録時にMailerアクションの存在を確認する。購読解除・重複登録・配送保証の扱いはJobと同じ。
`test/subscribable_mailer_test.rb`で、実際のMailDeliveryJobを通したシリアライズ・配送を検証する。

## 開発

Ruby 3.2以上、検証対象Railsコンポーネントは8.1.3.1。

```sh
bundle install
bundle exec rake
gem build chirin.gemspec
```

## 最小Railsアプリ

`test/dummy` に、SQLiteのメモリDBを使うRails 8.1.3.1アプリがある。
`bundle exec rake` で単体テストとリクエストレベルの統合テストを実行できる。
統合テストだけなら `bundle exec ruby -Ilib:test test/order_flow_test.rb`。

`POST /orders` → `OrderForm` → 注文・明細・受付時点の宛先を同一トランザクションで保存
→ commit後に `Events::OrderPlaced` → `OrderReceiptJob` → `OrderMailer` の順に動く。
独自serializerがOrderをGlobalIDとして持ち回り、ジョブ実行時に再取得する。
メールの宛先はCustomerの最新情報ではなくOrderのスナップショットを使う。

テストでは受付成功、顧客メール変更後の配送、明細不正時のrollback、外側のtransactionのrollback、
過去注文のインポートで受付メールが出ないことを確認する。
テスト用アプリはリロードを無効化し、一度だけ購読登録する。
after_commitはRails標準のAPIを直接使用する。配送保証や再実行時の重複防止はまだ扱わない。
既存の注文フローはJobアダプター経由で維持し、Mailer用DSLは別の統合テストで検証する。

## 次に進める順序

1. 購読の所有・解除・再読み込みの仕組みを決める。
2. サンプルのcommit後の報告をChirinのAPIにするか判断する。

在庫引当はその後の拡張例。outboxは別の設計課題として扱う。
ライセンスと公開先は公開前に決める。現段階はローカルで開発・コミットする。
