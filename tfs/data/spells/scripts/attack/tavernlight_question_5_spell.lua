local TORNADO_SPELL_AREA = { -- the aoe of the spell
	{0, 0, 0, 1, 0, 0, 0,},
	{0, 0, 1, 1, 1, 0, 0,},
	{0, 1, 1, 1, 1, 1, 0,},
	{1, 1, 1, 2, 1, 1, 1,},
	{0, 1, 1, 1, 1, 1, 0,},
	{0, 0, 1, 1, 1, 0, 0,},
	{0, 0, 0, 1, 0, 0, 0,}
}
local TORNADO_SPELL_WIDTH = 7 -- the width of the spell aoe
local TORNADO_SPELL_HEIGHT = 7 -- the height of the spell aoe

local NUM_TORNADO_PATTERNS = 4 -- the number of tornado visual patterns per cast
local TIMES_TORNADO_PATTERNS_REPEATED = 3 -- the number of times the tornado visual patterns are repeated per cast
local TORNADOS_PER_PATTERN = {8, 6, 6, 4} -- the number of tornadoes spawned for each pattern (to add some visual variety and make the casting have more immediate impact)

local combat = Combat() -- the base spell and it's damage/effects 
combat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)
combat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_NONE)
combat:setArea(createCombatArea(TORNADO_SPELL_AREA))

-- onGetFormulaValues: callback function to determine the combat formula values (copied directly from data/spells/scripts/attack/eternal_winter.lua)
function onGetFormulaValues(player, level, magicLevel)
	local min = (level / 5) + (magicLevel * 5.5) + 25
	local max = (level / 5) + (magicLevel * 11) + 50
	return -min, -max
end

combat:setCallback(CALLBACK_PARAM_LEVELMAGICVALUE, "onGetFormulaValues")

-- getTornadoOffsetsFromBase: returns a set of positional offsets for spawning tornado visuals based on the area of the spell and the caster position
local function getTornadoOffsetsFromBase()
	local tornadoOffsets = {}

	-- determine the position the spell is casted from
	local casterPosition = {x = 1, y = 1}
	for i = 1, TORNADO_SPELL_HEIGHT do
		for j = 1, TORNADO_SPELL_WIDTH do
			if TORNADO_SPELL_AREA[i][j] == 2 or TORNADO_SPELL_AREA[i][j] == 3 then
				casterPosition.x = j
				casterPosition.y = i
				break
			end
		end
	end

	-- calculate all offsets for tornado visuals to be spawned at relative to the casting position
	for i = 1, TORNADO_SPELL_HEIGHT do
		for j = 1, TORNADO_SPELL_WIDTH do
			if TORNADO_SPELL_AREA[i][j] == 1 or TORNADO_SPELL_AREA[i][j] == 3 then
				table.insert(tornadoOffsets, {x = j - casterPosition.x, y = i - casterPosition.y})
			end
		end
	end

	return tornadoOffsets
end

-- getRandomizedTornadoPatterns: returns a randomized set of patterns of tornado visual spawning offsets
--     originally, tornado spawning was going to be handled by combats with randomized areas
--     however, combat areas are not allowed to be defined at runtime
--     as such, we need to know where the tornadoes will be visually spawned at relative to the caster
local function getRandomizedTornadoPatterns()
	-- get the full set of positional offsets for tornado visuals
	local tornadoOffsets = getTornadoOffsetsFromBase()

	-- randomize the patterns for tornado visual spawning offsets
	local patterns = {}
	for i = 1, NUM_TORNADO_PATTERNS do
		-- define a pattern for tornado visual spawning offsets
		local pattern = {}
		for j = 1, TORNADOS_PER_PATTERN[i] do
			-- check if there are still tornado offsets to be picked
			if #tornadoOffsets <= 0 then
				break
			end

			-- pick a random offset from the set of tornado offsets and remove it from the set
			local randOffsetIndex = math.random(#tornadoOffsets)
			local randOffset = tornadoOffsets[randOffsetIndex]
			table.remove(tornadoOffsets, randOffsetIndex)

			-- add the tornado offset selected to the tornado spawning pattern
			table.insert(pattern, randOffset)
		end

		-- add the tornado spawning pattern to the set of patterns
		table.insert(patterns, pattern)
	end

	return patterns
end

-- castTornadoSpell: casts spell damage/effects and spawns tornado visuals for the given pattern
local function castTornadoSpell(creatureId, variant, tornadoPattern)
    local creature = Creature(creatureId)
    if creature then
		-- manually spawn in the tornado visuals 
		for i = 1, #tornadoPattern do
			-- get the position of the tornado based on the casting creature's current position
			local tornadoOffset = tornadoPattern[i]
			local position = creature:getPosition()
			position.x = position.x + tornadoOffset.x
			position.y = position.y + tornadoOffset.y

			-- spawn in tornado visual at defined position
			doSendMagicEffect(position, CONST_ME_ICETORNADO)
		end

		-- apply spell damage/effects
		return combat:execute(creature, variant)
	end
end

-- onCastSpell: callback function to handle casting of spell damage/effects and spawning of tornado visuals
function onCastSpell(creature, variant)
	local creatureId = creature:getId()

	-- get randomized patterns of tornado visuals for this casting
	local tornadoPatterns = getRandomizedTornadoPatterns()

	-- delay spawning of tornado visuals and repeated casts of spell damage/effects
	for i = 1, NUM_TORNADO_PATTERNS * TIMES_TORNADO_PATTERNS_REPEATED - 1 do
		local pattern = tornadoPatterns[(i % NUM_TORNADO_PATTERNS) + 1]
		addEvent(castTornadoSpell, 240 * i, creatureId, variant, pattern)
	end

	-- cast inital spell damage/effects and spawn initial tornado visuals
	return castTornadoSpell(creatureId, variant, tornadoPatterns[1])
end
