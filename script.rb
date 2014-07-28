require 'addressable/uri'
require 'rest-client'
require 'json'
require 'nokogiri'

# google project id: tenacious-coder-655
# geocoding request format: https://maps.googleapis.com/maps/api/geocode/output?parameters
# parameters: address, key

api_key = File.read(".api_key")

puts "What is your address?"
address = gets.chomp

request_url = Addressable::URI.new(
  :scheme => "https",
  :host => "maps.googleapis.com",
  :path => "maps/api/geocode/json",
  :query_values => { :address => address, :key => api_key }
).to_s

response = RestClient.get(request_url)
response_hash = JSON.parse(response)

lat = response_hash["results"].first["geometry"]["location"]["lat"]
lng = response_hash["results"].first["geometry"]["location"]["lng"]

request_url = Addressable::URI.new(
  :scheme => "https",
  :host => "maps.googleapis.com",
  :path => "maps/api/place/nearbysearch/json",
  :query_values => {
    key: api_key,
    location: "#{lat},#{lng}",
    rankby: "distance",
    keyword: "ice cream"
  }
).to_s

response = RestClient.get(request_url)
response_hash = JSON.parse(response)

puts response_hash

restaurant_list = response_hash["results"].map do |result|
  [result["name"], result["vicinity"]]
end

restaurant_list.each_with_index do |restaurant, i|
  puts "#{i+1}. #{restaurant.first} : #{restaurant.last}"
end

puts "Select an ice cream shop for directions."
selection = Integer(gets.chomp) - 1

selected_address = restaurant_list[selection].last

request_url = Addressable::URI.new(
  :scheme => "https",
  :host => "maps.googleapis.com",
  :path => "maps/api/directions/json",
  :query_values => {
    key: api_key,
    origin: address,
    destination: selected_address,
    mode: "walking"
  }
).to_s

response = RestClient.get(request_url)
response_hash = JSON.parse(response)

steps = response_hash["routes"].first["legs"].first["steps"].map do |step|
  mod_html = step["html_instructions"].gsub(/<div style=\"font-size:0.9em\">/, ". ")
  parsed_html = Nokogiri::HTML(mod_html)
  [parsed_html.text, step["distance"]["text"]]
end

steps.each_with_index do |step, i|
  if i + 1 != steps.count
    puts "#{i + 1}. #{step.first}. Continue for #{step.last}."
  else
    puts "#{i + 1}. #{step.first}."
  end
end



