-- movement dash hotkeys
local HOTKEY_DASHNORTH = 'Alt+Up'
local HOTKEY_DASHSOUTH = 'Alt+Down'
local HOTKEY_DASHWEST = 'Alt+Left'
local HOTKEY_DASHEAST = 'Alt+Right'

-- movement dash opcodes
local OPCODE_DASHNORTH = 11
local OPCODE_DASHSOUTH = 12
local OPCODE_DASHWEST = 13
local OPCODE_DASHEAST = 14

-- tell the server to activate the movement dash effect on the client player
local function sendDashPacket(opcode)
	local player = g_game.getLocalPlayer()
	if player then
		local protocolGame = g_game.getProtocolGame()
		if protocolGame then
			protocolGame:sendExtendedOpcode(opcode, '')
		end
	end
end

-- activate movement dash effect northwards
local function dashNorth()
	sendDashPacket(OPCODE_DASHNORTH)
end

-- activate movement dash effect southwards
local function dashSouth()
	sendDashPacket(OPCODE_DASHSOUTH)
end

-- activate movement dash effect westwards
local function dashWest()
	sendDashPacket(OPCODE_DASHWEST)
end

-- activate movement dash effect eastwards
local function dashEast()
	sendDashPacket(OPCODE_DASHEAST)
end

-- bind hotkeys to the movement dash effect on module load
function init()
	g_keyboard.bindKeyDown(HOTKEY_DASHNORTH, dashNorth)
	g_keyboard.bindKeyDown(HOTKEY_DASHSOUTH, dashSouth)
	g_keyboard.bindKeyDown(HOTKEY_DASHWEST, dashWest)
	g_keyboard.bindKeyDown(HOTKEY_DASHEAST, dashEast)
end

-- unbind movement dash effect hotkeys on module unload
function terminate()
	g_keyboard.unbindKeyDown(HOTKEY_DASHNORTH)
	g_keyboard.unbindKeyDown(HOTKEY_DASHSOUTH)
	g_keyboard.unbindKeyDown(HOTKEY_DASHWEST)
	g_keyboard.unbindKeyDown(HOTKEY_DASHEAST)
end