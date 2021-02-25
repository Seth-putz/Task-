require_relative 'methods.rb'
require "mysql2"
require 'dotenv/load'
client = Mysql2::Client.new(host: "db09.blockshopper.com", username: ENV['DB09_LGN'], password: ENV['DB09_PWD'])
client.query("use applicant_tests")
#puts mt_dstrct_rprt_crd(client)
puts mt_dstrct_rprt_crd(client)

# t = Time.now
# mt_dstrct_rprt_crd(client)
# puts Time.now - t
client.close


