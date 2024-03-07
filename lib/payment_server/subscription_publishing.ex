defmodule PaymentServer.SubscriptionPublishing do
  
  def publish_total_worth_change(user_id, worth_change) do
    pubsub = PaymentServerWeb.Endpoint
    Absinthe.Subscription.publish(pubsub, worth_change, total_worth_changed: to_string(user_id))
  end

end