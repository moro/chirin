# Chirin

イベントの呼び鈴が鳴ったら、後続処理へ。

Rails.event と Active Job をつなぐ、小さなEDAのコンセプト実装。
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

イベントクラスも購読できる。`subscribe(Events::OrderPlaced)` はpayloadの型を判定する。
ジョブに渡すのはSERのevent Hash全体ではなくpayload。
独自イベントオブジェクトはActive Jobのserializerを別途用意する必要がある。
テストにシリアライズ・復元・実行の最小例がある。
オブジェクト形式でnotifyした場合のSERのnameはクラス名であり、文字列のorder.placedとは異なる。

購読者の呼び出しとジョブ投入は同期で行う。実行が非同期になるかはキューアダプターによる。
例外処理はEventReporterとActive Jobの設定に従う。通知の永続化・配送保証は追加しない。

## 開発

Ruby 3.2以上、検証対象Railsコンポーネントは8.1.3.1。

```sh
bundle install
bundle exec rake
gem build chirin.gemspec
```

## 次に進める順序

1. 小さなRailsアプリでOrderと明細を保存し、注文受付のrequest specからジョブを実行する。
2. GlobalIDを使うイベントの復元を検証する。受付時点の必要情報はOrder側に保存する。
3. `SubscribableMailer` を追加し、注文受付メールまで確かめる。
4. 購読の所有・解除・再読み込みの仕組みを決める。
5. commit後の報告を追加し、rollback時に報告しないことを検証する。

在庫引当はその後の拡張例。outboxは別の設計課題として扱う。
ライセンスと公開先は公開前に決める。現段階はローカルで開発・コミットする。
