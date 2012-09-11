# Ruby Neuro Server Components

## server.rb
A simple socket implementation that accepts connections on port 8336 and spans a new thread for Client execution.

The server can be run with command:
  ruby server.rb
  
It can be tested with:
    $ telnet localhost 8336
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is '^]'.
  
Once connected, one can send NeuroServer commands:
    hello
    200 OK
    
A list of available commands can be obtained sending help command:
    help
    hello: Healthcheck
    close: Close client connection
    role: Displays client role [CONTROLLER, EEG, DISPLAY]
    control: Starts a CONTROLLER client, that can send commands to another clients
    eeg: Starts an EEG client
    display: Starts a DISPLAY client
    status: Shows status of connected clients
    go: Go command for controllers. go 0 activates a go trial in EEG device 0
    nogo: No Go command for controllers
    setheader: Sets EDFHeaders
    setcheader: Sets EDFChannelHeaders
    watch: Enables displays to receive data frames
    unwatch: Disables displays to receive data frames
    getheader: Prints all headers

## command_handler.rb
It just interprets commands received from connected clients.

## data_structures.rb
Data structures for header commands. These data headers refers to:
 * capture data (patient, equipment, etc); and 
 * channels data (unit, measure ranges, labels, etc).

## client.rb
Encapsulates logic for all available commands.

### Roles
All clients have a role, which initial value is UNSET. The available roles are CONTROLLER, EEG and DISPLAY. To assume these roles, one can issue the commands control, eeg or display, respectively. Once the role is set, it cannot be changed.
Each role has a subset of commands available. Issuing a command that is not applicable to a role results in a BAD REQUEST response.

#### Controller
A Controller client can send messages to other connected clients. Currently, there are only two actions for controllers (go, nogo).
Supposing two clients connected, the following example shows a control session between them:

Controller Client
    Escape character is '^]'.
    control
    200 OK
    role
    200 OK
    CONTROLLER
    go 2
    200 OK
    nogo 2
    200 OK

Another Client (any role)
    Escape character is '^]'.
    go
    nogo

Only one controller client can be active at any moment.

#### EEG
An client accepts setheader and setcheader commands to configure headers with patient and channels data, respectively.
Available header options can be found in data_structures.rb.

#### Display
A client display can be used to view current headers for other EEG clients. This example shows two EEG/Display sessions iteractions.

EEG Client
    Escape character is '^]'.
    eeg
    200 OK  
    setheader patient Mary
    200 OK
    setcheader 0 label ch1
    200 OK
    setcheader 1 label ch2
    200 OK

Display Client
    Escape character is '^]'.
    display
    200 OK
    status
    200 OK
    controller: 
    display: 2
    eeg: 1
    unset: 
    getheader 1
    patient Mary start_time 2012-09-11/17:41:48-0300 label ch1 label ch2