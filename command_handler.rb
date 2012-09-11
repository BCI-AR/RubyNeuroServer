require 'optparse'

class CommandHandler
  def initialize(client)
    @client = client
  end

  def help_message
    {
      hello:              "Healthcheck",
      close:              "Close client connection",
      role:               "Displays client role [CONTROLLER, EEG, DISPLAY]",
      control:            "Starts a CONTROLLER client, that can send commands to another clients",
      eeg:                "Starts an EEG client",
      display:            "Starts a DISPLAY client",
      status:             "Shows status of connected clients",
      "go N"          =>  "Go command for controllers. go 0 activates a go trial in EEG device 0",
      "nogo N"        =>  "No Go command for controllers",
      setheader:          "EEG command to set EDFHeaders",
      "setcheader CH" =>  "EEG command to set EDFChannelHeaders for channel CH",
      "getheader N"   =>  "Display command to print all headers for EEG #N",
      watch:              "Display command to enable data frames receipt",
      unwatch:            "Display command to disable data frames receipt",
      "! P CC M1 M2.."=>
      %{Data frame for each CC channels having P packet_size, with its Mi measures.
      M1, M2, M3, ... refers to the P * CC measures in each channel.
      It's broadcasted for all display clients that are in watch state.}
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
      @client.get_header args[1]
    when "!"
      @client.data_frame args[1], args[2], args[3..n]
    end
  end
end
