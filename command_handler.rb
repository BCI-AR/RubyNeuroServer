require 'optparse'

class CommandHandler
  def initialize(client)
    @client = client
  end

  def help_message
    {
      hello:      "Healthcheck",
      close:      "Close client connection",
      role:       "Displays client role [CONTROLLER, EEG, DISPLAY]",
      control:    "Starts a CONTROLLER client, that can send commands to another clients",
      eeg:        "Starts an EEG client",
      display:    "Starts a DISPLAY client",
      status:     "Shows status of connected clients",
      go:         "Go command for controllers.\ngo 0 activates a go trial in EEG device 0",
      nogo:       "No Go command for controllers",
      watch:      "Enables displays to receive data frames",
      unwatch:    "Disables displays to receive data frames",
      setheader:  "Sets EDFHeaders",
      setcheader: "Sets EDFChannelHeaders",
      getheader:  "Prints all headers"
    }.collect { |k,v|
      "#{k}: #{v}"
    }.join "\n"
  end

  def parse(command)
    puts "handling #{command}"
    args = command.split " "
    n = args.count
    case args[0]
    when "help"
      @client.send_message help_message
    when "hello"
      @client.hello
    when "close"
      @client.close
    when "role"
      @client.role
    when "control"
      @client.control
    when "eeg"
      @client.eeg
    when "display"
      @client.display
    when "status"
      @client.status
    when "go"
      @client.go args[1]
    when "nogo"
      @client.go args[1], "nogo"
    when "watch"
      @client.watch true
    when "unwatch"
      @client.watch false
    when "setheader"
      @client.set_header args[1..n]
    when "setcheader"
      @client.set_channel_header args[1], args[2..n]
    when "getheader"
      @client.get_header
    when "!"
      @client.data_frame args[1], args[2], args[3..n]
    end
  end
end
