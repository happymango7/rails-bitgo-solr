require "omnicontacts"

Rails.application.middleware.use OmniContacts::Builder do
  importer :gmail, "449109251723-mt5jbuh9i5oblsdldos89109q3laum08.apps.googleusercontent.com", "MO6NyX1rofV083BSPzJvklKF", {:redirect_path => "/oauth2callback"}
  #Development
  # importer :yahoo, "dj0yJmk9ZmNRNzN2Zkx0T0UzJmQ9WVdrOVJEZEViVXRMTXpJbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1mOQ--", "6b513da14b41b15761e1a574b864cf5b728418af", {:callback_path => '/callback'}
  #Production
  importer :yahoo, "dj0yJmk9TVM3WkRwc3Y3dWZUJmQ9WVdrOU5YWTJRM28zTXpBbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1jNQ--", "b8f5c3adb1097a525298510ebc91d61d2bddb180", {:callback_path => '/callback'}
end
