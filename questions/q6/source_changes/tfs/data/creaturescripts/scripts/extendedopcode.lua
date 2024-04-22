local OPCODE_LANGUAGE = 1

-- opcodes for the different movement dash inputs
local OPCODE_AFTERIMAGE = 10
local OPCODE_DASHNORTH = 11
local OPCODE_DASHSOUTH = 12
local OPCODE_DASHWEST = 13
local OPCODE_DASHEAST = 14

-- storage key for the movement dash effect
local DASH_STORAGE_KEY = 100000

-- table for checking which opcodes correspond to the movement dash effect
local dashingOpcodes = {
	[OPCODE_DASHNORTH] = true,
	[OPCODE_DASHSOUTH] = true,
	[OPCODE_DASHWEST] = true,
	[OPCODE_DASHEAST] = true,
}

-- table for converting movement dash opcodes to directions
local dashingOpcodeDirection = {
	[OPCODE_DASHNORTH] = DIRECTION_NORTH,
	[OPCODE_DASHSOUTH] = DIRECTION_SOUTH,
	[OPCODE_DASHWEST] = DIRECTION_WEST,
	[OPCODE_DASHEAST] = DIRECTION_EAST,
}

-- send the state of the afterimage visual effect to the client
local function sendAfterimageStateToClient(player, shouldRender)
	-- https://otland.net/threads/trying-to-receive-a-storage-value-from-tfs-otclient.265046/#post-2565837

	local packet = NetworkMessage()
	packet:addByte(0x32) -- extended opcode
	packet:addByte(OPCODE_AFTERIMAGE) -- afterimage extended opcode
	
	packet:addU32(player:getId()) -- id of the player
	packet:addByte(shouldRender and 0x01 or 0x00) -- current state of the visual effect
	packet:sendToPlayer(player)
	packet:delete()
end

-- single step of the movement dash effect
local function dashForwards(playerId, variant)
	-- check if player exists
	local player = Player(playerId)
	if player and player:isPlayer() then
		local direction = player:getDirection()
		local position = player:getPosition()
		
		-- check that the next position we are moving to is valid
		position:getNextPosition(direction, 1)
		position = player:getClosestFreePosition(position, 0)
		if position.x ~= 0 or position.y ~= 0 or position.z ~= 0 then
			-- position is valid, move to position instantly
			player:teleportTo(position)
		end
	end
end

-- resets states associated with the movement dash effect
local function finishDashEffect(playerId, variant)
	-- check if player exists
	local player = Player(playerId)
	if player and player:isPlayer() then
		player:setMovementBlocked(false) -- allow player to manually move again
		sendAfterimageStateToClient(player, false) -- disable afterimage effect state on player
		player:setStorageValue(DASH_STORAGE_KEY, -1) -- allow movement dash to be used again
	end
end

-- sets up the movement dash effect
local function beginDashEffect(player, direction)
	-- check if player exists and is not currently dashing
	if player:isPlayer() and player:getStorageValue(DASH_STORAGE_KEY) == -1 then
		local playerId = player:getId()
		
		player:setMovementBlocked(true) -- prevent player from being able to move manually during the effect
		sendAfterimageStateToClient(player, true) -- enable afterimage effect state on player
		player:setStorageValue(DASH_STORAGE_KEY, 1) -- disallow movement dash effect from starting in the middle of existing dash
		
		-- turn player to the inputted direction
		if direction then
			player:setDirection(direction)
		end
		
		-- add events for steps of the movement dash and the end of the effect
		for i = 1, 9 do
			addEvent(dashForwards, 30 * i, playerId, variant)
		end
		dashForwards(playerId, variant)
		addEvent(finishDashEffect, 30 * 10, playerId, variant)
	end
end

function onExtendedOpcode(player, opcode, buffer)
	if opcode == OPCODE_LANGUAGE then
		-- otclient language
		if buffer == 'en' or buffer == 'pt' then
			-- example, setting player language, because otclient is multi-language...
			-- player:setStorageValue(SOME_STORAGE_ID, SOME_VALUE)
		end
	elseif dashingOpcodes[opcode] then
		-- extended opcode is movement dash effect, try starting effect if player exists
		if player:isPlayer() then
			beginDashEffect(player, dashingOpcodeDirection[opcode])
		end
	else
		-- other opcodes can be ignored, and the server will just work fine...
	end
end
