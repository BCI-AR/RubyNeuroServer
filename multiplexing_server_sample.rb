#!/usr/bin/env ruby
#-*- coding: utf-8 -*-

# Based on:
# The Ruby Programming Language, 9.8.5 - A Multiplexing Server
# This implementation is based on #select method, avoiding Threads usage

require 'socket'

server = TCPServer.open(8336)
sockets = [server]
log = STDOUT
loop do
  ready = select(sockets)  # Block and wait for a socket to be ready
  readable = ready[0]

  readable.each do |socket|
    if socket == server
      client = server.accept  # Accept a new client
      sockets << client

      client.puts "RubyNeuroServer v0.0.1 running on #{Socket.gethostname}"
      log.puts "Accepted connection from #{client.peeraddr[2]}"
    else # Otherwise, a client is ready
      input = socket.gets

      # If no input, the client has disconnected
      if !input
        log.puts "Client on #{socket.peeraddr[2]} disconnected."
        sockets.delete(socket)
        socket.close
        next
      end

      input.chop!
      if input == "close"
        socket.puts("Bye!");
        log.puts "Closing connection to #{socket.peeraddr[2]}"
        sockets.delete(socket)
        socket.close
      else
        # socket.puts(input.reverse)
        id = sockets.index socket
        log.puts "Client #{id}: #{input}"
        if id == 1
          others = sockets - [server, socket]

          log.puts "Broadcasting from #{id} to: " +
            others.collect{|o| sockets.index(o)}.sort.join(', ')

          others.each {|other| other.puts input }
        end
      end
    end
  end
end
