load 'consume_aviary_fx.rb'

# The following code insantiates the consumer class and calls each
# of the test methods, outputting the results returned

# Be sure to enter the appropriate api_key and api_secret

cafx = ConsumeAviaryFX.new("demoapp", "demoappsecret")

puts "Testing get_filters. Result is:"
puts cafx.test_get_filters

puts "Testing upload. Result is:"
puts cafx.test_upload
imageUrl = cafx.test_upload[:url]

puts "Testing render_options. Result is:"
puts cafx.test_render_options(imageUrl)

puts "Testing render. Result is:"
puts cafx.test_render(imageUrl)


