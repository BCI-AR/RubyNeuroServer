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

  attr_reader :index, :config, :type

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
    execute { [ SUCCESS, @type ] }
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

  def get_header(client_id)
    execute {
      next type_request_invalid_to_role "getheader", "DISPLAY" unless @type == "DISPLAY"
      c = client_by_id client_id
      next c.type_request_invalid_to_role "getheader", "EEG" unless c.type == "EEG"
      [ SUCCESS, c.config.to_s ]
    }
  end

  def set_header(headers)
    execute {
      next type_request_invalid_to_role "setheader", "EEG" unless @type == "EEG"
      headers = Hash[*headers]
      headers[:start_time] = Time.now
      @config.header ||= EDFHeader.new
      @config.header.update_attributes headers
      SUCCESS
    }
  end

  def set_channel_header(channel, headers)
    execute {
      next type_request_invalid_to_role "setcheader", "EEG" unless @type == "EEG"
      @config.channel_headers[channel.to_i] ||= EDFChannelHeader.new
      @config.channel_headers[channel.to_i].update_attributes Hash[*headers]
      SUCCESS
    }
  end

  def data_frame(packet_counter, channel_count, data)
    execute {
      next invalid_channel_count(channel_count) unless channel_count.to_i.between? 0, MAX_CHANNELS
      @@instances[:display].each { |c|
        c.send_message "! 0 #{data.join ' '}\r\n" if c.is_displaying?
      }
      SUCCESS
    }
  end

  def watch(state)
    execute {
      next invalid_command "watch" unless @type == "DISPLAY"
      @is_displaying = state
      SUCCESS
    }
  end

  def go(recv_index, msg="go")
    execute {
      next type_request_invalid_to_role "go", "CONTROLLER" unless @type == "CONTROLLER"
      receiver = client_by_id recv_index
      puts "Sending [#{msg}] from #{@index} to #{receiver.index}"
      receiver.send_message msg
      SUCCESS
    }
  end

  def close
    @@instances[@type.downcase.to_sym].delete self
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

  def type_request_invalid_to_role(type, role)
    [
      BAD_REQUEST,
      "Only #{role} accepts #{type} request. #{@index} role is #{@type}."
    ]
  end

  private
  def update_last_alive
    @last_alive = Time.now
  end

  def execute
    begin
      status, message = yield
      send status, message
    rescue Exception => e
      send "ERROR", e.message
    end
  end

  def invalid_command(cmd)
    [ BAD_REQUEST, "#{cmd} command cannot be sent to client with role #{@type}" ]
  end

  def controller_already_set
    index = @@instances[:controller].first.index
    [ BAD_REQUEST, "controller already set to client ##{index}" ]
  end

  def set_role(role)
    unset = (@type.nil? or @type == "UNSET")
    return [ BAD_REQUEST, "role already set to #{@type}" ] unless unset
    type = role.downcase.to_sym
    @@instances[type] << self
    @@instances[:unset].delete self unless type == :unset
    @type = role
    SUCCESS
  end

  def invalid_channel_count(channel_count)
    [
      BAD_REQUEST,
      "Channel count [#{channel_count}] should be between 0 and #{MAX_CHANNELS}"
    ]
  end

  def client_by_id(id)
    id = id.to_i
    raise "Client #{id} does not exist" unless @@instances_by_index.include? id
    @@instances_by_index[id]
  end
end
