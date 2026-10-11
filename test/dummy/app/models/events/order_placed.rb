module Events
  OrderPlaced = Data.define(:order) do
    include Chirin::Event
  end
end
