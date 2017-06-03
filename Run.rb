require './Config/Config.rb'
require './Extensions/Crumbs.rb'
require './Extensions/Database.rb'
require './Extensions/TCP.rb'
require './Extensions/XTParser.rb'

require './Core/Gaming/FindFour.rb'

require './Core/Login.rb'
require './Core/Game.rb'

require './Core/ClubPenguin.rb'
require './Core/CPUser.rb'


server = ClubPenguin.new(getConfig)

server.startEmulator

while true
	server.sock.listenServer
end
