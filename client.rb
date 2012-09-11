require './command_handler'
require './data_structures'

class Client
  SUCCESS = "200 OK"
  BAD_REQUEST = "400 BAD REQUEST"
  MAX_CHANNELS = 32

  @@count = 0
  @@instances = {
    controller: [], display: [], eeg: [], unset: []
  }
  @@instances_by_index = {}

  attr_reader :index

  def is_displaying?
    @is_displaying
  end

  def initialize(socket)
    update_last_alive
    set_role "UNSET"
    @socket = socket
    @index  = @@count += 1
    @@instances_by_index[@index] = self

    @config = EDFConfig.new
    @handler = CommandHandler.new self
    puts "Accepting connection #{@index} at #{@last_alive}"
    loop {
      @handler.parse socket.readline.strip
      break if @finished
    }
    socket.close
  end

  def hello
    execute { SUCCESS }
  end

  def role
    execute { [ SUCCESS, @role ] }
  end

  def control
    execute {
      next controller_already_set unless @@instances[:controller].empty?
      set_role "CONTROLLER"
    }
  end

  def eeg
    execute { set_role "EEG" }
  end

  def display
    execute {
      res = set_role "DISPLAY"
      @is_displaying = true if res == SUCCESS
      res
    }
  end

  def status
    execute {
      res = []
      @@instances.each { |type,clients|
        indexes = clients.collect { |c| c.index }
        res << "#{type}: #{indexes.join(', ')}"
      }
      [ SUCCESS, res.join("\r\n") ]
    }
  end

  def get_header
    execute {
      next type_request_invalid_to_role "getheader", "DISPLAY" unless @role == "DISPLAY"
      [ SUCCESS, @config.to_s ]
    }
  end

  def set_header(headers)
    execute {
      next type_request_invalid_to_role "setheader", "EEG" unless @role == "EEG"
      @config.header = EDFHeader.new Hash[headers]
      @config.header.start_time = Time.now
      SUCCESS
    }
  end

  def set_channel_header(channel, headers)
    execute {
      next type_request_invalid_to_role "setcheader", "EEG" unless @role == "EEG"
      @config.channel_headers[channel.to_i] = EDFChannelHeader.new Hash[headers]
      @config.header.start_time = Time.now
      SUCCESS
    }
  end

  def data_frame(packet_counter, channel_count, data)
    execute {
      next invalid_channel_count(channel_count) unless channel_count.to_i.between? 0, MAX_CHANNELS
      puts @@instances[:display]
      @@instances[:display].each { |c|
        puts c.is_displaying?
        c.send_message "! 0 #{data.join ' '}\r\n" if c.is_displaying?
      }
      SUCCESS
    }
  end

  def watch(state)
    execute {
      next invalid_command "watch" unless @role == "DISPLAY"
      @is_displaying = state
      SUCCESS
    }
  end

  def go(recv_index, msg="go")
    execute {
      next type_request_invalid_to_role "go", "CONTROLLER" unless @role == "CONTROLLER"
      @role == "CONTROLLER"
      receiver = @@instances_by_index[recv_index.to_i]
      puts "Sending [#{msg}] from #{@index} to #{receiver.index}"
      receiver.send_message msg
      SUCCESS
    }
  end

  def close
    @@instances[@role.downcase.to_sym].delete self
    @@instances_by_index.delete self.index
    @finished = true
  end

  def send(status_line, response=nil)
    send_message status_line
    send_message response unless response.nil?
  end

  def send_message(msg)
    @socket.print "#{msg}\r\n"
    update_last_alive
  end

  private
  def update_last_alive
    @last_alive = Time.now
  end

  def execute
    begin
      status, message = yield
      send status, message
    rescue
      send "ERROR"
    end
  end

  def invalid_command(cmd)
    [ BAD_REQUEST, "#{cmd} command cannot be sent to client with role #{@role}" ]
  end

  def controller_already_set
    index = @@instances[:controller].first.index
    [ BAD_REQUEST, "controller already set to client ##{index}" ]
  end

  def set_role(role)
    unset = (@role.nil? or @role == "UNSET")
    return [ BAD_REQUEST, "role already set to #{@role}" ] unless unset
    type = role.downcase.to_sym
    @@instances[type] << self
    @@instances[:unset].delete self unless type == :unset
    @role = role
    SUCCESS
  end

  def invalid_channel_count(channel_count)
    [
      BAD_REQUEST,
      "Channel count [#{channel_count}] should be between 0 and #{MAX_CHANNELS}"
    ]
  end

  def type_request_invalid_to_role(type, role)
    [ BAD_REQUEST, "Only #{role} accepts #{type} request" ]
  end
end
