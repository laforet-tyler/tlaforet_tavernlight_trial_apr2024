local jumpWindow        = nil -- Jump! window
local jumpTopMenuButton = nil -- Jump! top-bar button (toggles window on/off)
local jumpButton        = nil -- Moving Jump! button

-- margins for moving the Jump! button around
local currentMarginTop  = math.random(130)
local currentMarginLeft = 130

-- variables for controlling movement of the Jump! button
-- utilizes delta time approach to avoid the movement being dependent on frame rate
local lastClockTime = os.clock()
local totalDelta = 0.0

function online()
	-- enables the top menu button upon logging into the game and entering the world
	-- modified from modules/game_spelllist/spelllist.lua
	jumpTopMenuButton:show()
end

function offline()
	-- disables ui features upon logging out of the game_world
	-- modified from modules/game_spelllist/spelllist.lua
	resetWindow()
end

local function setJumpButtonMargins()
	-- sets the margins of the Jump! button to the current stored values
	jumpButton:setMarginTop(currentMarginTop)
	jumpButton:setMarginLeft(currentMarginLeft)
end

function updateJumpButton()
	-- updates the position of the moving Jump! button
	-- utilizes a custom callback 'onPoll' defined in otclient/src/framework/core/graphicalapplication.cpp: GraphicalApplication::run()
	-- allows us to hook into the main loop of the program and functions as a form of post-update callback for fully custom Lua features

	-- check for if the mod is properly loaded
	if jumpWindow ~= nil then
		-- get delta time since last poll
		local now = os.clock()
		local delta = now - lastClockTime

		-- update total delta since last movement of the button and update button position if necessary
		-- movement is only allowed to jump fixed amounts every 0.1 seconds
		-- this done instead of scaling movement as doing so proved too laggy due to the constant rendering foreground refreshes
		totalDelta = totalDelta + delta
		while totalDelta > 0.1 do
			-- move button left by lowering the margins
			currentMarginLeft = currentMarginLeft - 10

			-- if the button has reached past the left edge of the window, reset to a random position on the right of the window
			if currentMarginLeft < 0 then
				currentMarginTop = math.random(130)
				currentMarginLeft = 130
			end

			-- update the actual margins of the button only if the window is visible
			-- this is done to avoid unnecessary rendering foreground refreshes if the window is not currently showing
			if jumpWindow:isVisible() then
				setJumpButtonMargins()
			end

			-- reduce total delta time
			totalDelta = totalDelta - 0.1
		end

		-- set current time of poll
		lastClockTime = now
	end
end

function resetJumpButton()
	-- resets the margins of the jump button to a random location on the right side of the window
	currentMarginTop = math.random(130)
	currentMarginLeft = 130
	totalDelta = 0.0
	setJumpButtonMargins()
end

function init()
	-- enables and initializes Jump! ui features upon loading the module
	-- modified from modules/game_spelllist/spelllist.lua

	-- callbacks for Jump! ui features
	connect(g_game, {onGameStart = online,             -- enables the top menu button upon logging into the game and entering the world
	                 onGameEnd   = offline,})          -- disables ui features upon logging out of the game_world
	connect(g_app,  {onPoll      = updateJumpButton,}) -- updates the position of the moving Jump! button

	-- load the Jump! window
	jumpWindow = g_ui.displayUI('tavernlight_question_7_jumpui', modules.game_interface.getRightPanel())
	jumpWindow:hide()

	-- load the Jump! top menu button
	jumpTopMenuButton = modules.client_topmenu.addRightGameToggleButton('jumpTopMenuButton', tr('Jump!'), '/images/topbuttons/jump', toggle)
	jumpTopMenuButton:setOn(false)

	-- load the moving Jump! button
	jumpButton = jumpWindow:getChildById('buttonJump')
	resetJumpButton()

	-- enable the top menu button if the module is loaded mid-game
	if g_game.isOnline() then
		online()
	end
end

function terminate()
	-- disables Jump! ui features upon unloading the module

	-- turn off callbacks
	disconnect(g_game, {onGameStart = online,
	                    onGameEnd   = offline})
	disconnect(g_app, {onPoll = updateJumpButton})

	-- delete ui features
	jumpWindow:destroy()
	jumpTopMenuButton:destroy()
end

function toggle()
	-- toggles whether the jump window should be enabled/disabled and 
	-- the highlight state of the corresponding top menu button
	-- modified from modules/game_spelllist/spelllist.lua
	if jumpTopMenuButton:isOn() then
		-- hide window / de-highlight top menu button
		jumpTopMenuButton:setOn(false)
		jumpWindow:hide()
	else
		-- show windows / highlight top menu button / update Jump! button position
		jumpTopMenuButton:setOn(true)
		setJumpButtonMargins()
		jumpWindow:show()
		jumpWindow:raise()
		jumpWindow:focus()
	end
end

function resetWindow()
	-- hides the Jump! window and de-highlights the corresponding top menu button
	-- modified from modules/game_spelllist/spelllist.lua
	jumpWindow:hide()
	jumpTopMenuButton:setOn(false)
end