require 'rubygems'
require 'base64'
require 'openssl'
require 'sinatra'
require 'active_support/security_utils'
require 'shopify_api'

# The Shopify app's shared secret, viewable from the Partner dashboard
SHARED_SECRET = '859f40bf2cde140869bf3feb9d8223b51656cdcd4005fa2b179ba028d5af60a5'
API_KEY = 'eed5b07d8a7fa5f7e475c5a075890f3d'
PASSWORD = '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'
SHOP_NAME = 'Pardeeps-Ecommerce-Store'

# Shoify API gem setup
shop_url = "https://#{API_KEY}:#{PASSWORD}@#{SHOP_NAME}.myshopify.com"
ShopifyAPI::Base.site = shop_url
ShopifyAPI::Base.api_version = '2020-07' # find the latest stable api_version here: https://shopify.dev/concepts/about-apis/versioning

helpers do
  # Compare the computed HMAC digest based on the shared secret and the request contents
  # to the reported HMAC in the headers
  def verify_webhook(data, hmac_header)
    calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest('sha256', SHARED_SECRET, data))
    unless ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
      return [403, 'Authorization failed. Provided hmac was #{hmac_header}']
    end  
  end
end

# Respond to HTTP POST requests sent to this web service
post '/webhook/product_update' do
  request.body.rewind
  data = request.body.read
  verified = verify_webhook(data, env["HTTP_X_SHOPIFY_HMAC_SHA256"])

  # Output 'true' or 'false'
  puts "Webhook verified: #{verified}"

  json_data = JSON.parse data

  product = ShopifyAPI::Product.find(json_data['id'].to_i)

  product.tags += ', Updated'
  product.save

  return [200, 'Webhook successfully received.']
end
