# Chirin

Small adapters connecting `Rails.event` to Active Job and Action Mailer.

[日本語](README.ja.md)

## Setup

Add your local checkout to the application's Gemfile, then run `bundle install`:

```ruby
gem "chirin", path: "../chirin"
```

Tested with Rails 8.1.3.1. Configure an Active Job queue adapter in your application.

## Usage

Define a named Data event. Including `Chirin::Event` enables serialization automatically.

```ruby
module Events
  OrderPlaced = Data.define(:order) do
    include Chirin::Event
  end
end
```

Subscribe a job or mailer. Both receive the event payload as their single argument.

```ruby
class ReserveInventoryJob < ApplicationJob
  include Chirin::SubscribableJob

  def perform(event)
    # Reserve inventory for event.order.
  end
end

class OrderMailer < ApplicationMailer
  include Chirin::SubscribableMailer

  def placed(event)
    mail(to: event.order.receipt_email,
         subject: "Order received", body: "Thank you for your order.")
  end
end

# Register once after the classes are loaded.
job_subscriber = ReserveInventoryJob.subscribe(Events::OrderPlaced)
mail_subscriber = OrderMailer.subscribe(:placed, Events::OrderPlaced)

# Report after the order's transaction commits.
Rails.event.notify(Events::OrderPlaced.new(order: order))
```

Jobs use `perform_later`; mailers use `deliver_later`.
String and Symbol event names are also supported; their payload is a Hash.
Class subscriptions match the exact class name, not subclasses.

## Notes

- Active Job serializes event attributes. Active Record objects are reloaded through GlobalID, not stored as snapshots. Workers must be able to load the event class.
- Register subscriptions explicitly. Repeated registration creates duplicates; automatic reload handling is not provided. Remove a subscription with `Rails.event.unsubscribe(job_subscriber)` before replacing it.
- Chirin does not manage transaction boundaries, persist notifications, or guarantee delivery. Enqueuing is synchronous; execution follows your queue adapter.

## Tests

```sh
bundle install
bundle exec rake
```
