# Chirin

`Rails.event`とActive Job・Action Mailerをつなぐ小さなアダプター。

[English](README.md)

## 導入

アプリケーションのGemfileにローカルのチェックアウトを追加し、`bundle install`します。

```ruby
gem "chirin", path: "../chirin"
```

Rails 8.1.3.1で検証しています。アプリケーション側でActive Jobのキューアダプターを設定してください。

## 使い方

名前付きのDataイベントを定義します。`Chirin::Event`をincludeすると、シリアライズが自動で有効になります。

```ruby
module Events
  OrderPlaced = Data.define(:order) do
    include Chirin::Event
  end
end
```

JobやMailerを購読登録します。どちらもイベントのpayloadを引数一つとして受け取ります。

```ruby
class ReserveInventoryJob < ApplicationJob
  include Chirin::SubscribableJob

  def perform(event)
    # event.orderの在庫を引き当てる。
  end
end

class OrderMailer < ApplicationMailer
  include Chirin::SubscribableMailer

  def placed(event)
    mail(to: event.order.receipt_email,
         subject: "ご注文を受け付けました", body: "ご注文ありがとうございます。")
  end
end

# クラスのロード後、一度だけ登録する。
job_subscriber = ReserveInventoryJob.subscribe(Events::OrderPlaced)
mail_subscriber = OrderMailer.subscribe(:placed, Events::OrderPlaced)

# 注文のトランザクションがcommitされた後に報告する。
Rails.event.notify(Events::OrderPlaced.new(order: order))
```

Jobは`perform_later`、Mailerは`deliver_later`で投入します。
文字列・Symbolのイベント名も指定でき、その場合のpayloadはHashです。
クラス指定はクラス名の完全一致で判定し、サブクラスは含みません。

## 注意点

- 属性のシリアライズはActive Jobに任せます。Active Recordはスナップショットではなく、GlobalIDで再取得します。ワーカーでもイベントクラスをロードできる必要があります。
- 購読は明示的に登録します。重複登録の防止やリロード対応は自動では行いません。登録し直す前に`Rails.event.unsubscribe(job_subscriber)`で解除してください。
- トランザクション境界の管理、通知の永続化、配送保証は行いません。ジョブ投入は同期で、実行方法はキューアダプターに従います。

## テスト

```sh
bundle install
bundle exec rake
```
