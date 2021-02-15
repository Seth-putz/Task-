require_relative 'methods.rb'
require "mysql2"
require 'dotenv/load'
client = Mysql2::Client.new(host: "db09.blockshopper.com", username: ENV['DB09_LGN'], password: ENV['DB09_PWD'])
client.query("use applicant_tests")
puts get_random_names(5 ,client)
t = Time.now
100.times do
  puts get_random_names(1, client)
end
puts Time.now - t

client.close


