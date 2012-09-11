puts "rbNSD (Ruby NeuroServer Daemon)"

require 'socket'
server = TCPServer.open 8336

require './client'
loop { # Servers run forever
  Thread.start server.accept do |client|
    Client.new client
  end
}
