local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- 
--	Header
--
-- -----------------------------------------------------------------------------------

---- GAMEHEADER ----

--loading spritesheets
local sheetFile = require( "sheet" )
local gFunc = require("gameFunctions")
--Loading physics and setting the gravity to 0
local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )
--physics.setDrawMode( "hybrid" ) --Uncomment this line to show hitboxes
--hiding the status bar
display.setStatusBar(display.HiddenStatusBar)

--------------------

---- VARIABLES ----

gFunc.gameVarInit()

--music var
local lvl1Track = "Sounds/Lvl 1.ogg"
local lvl2Track = "Sounds/Lvl 2.ogg"
local lvl3Track = "Sounds/Lvl 3.ogg"
--game specific vars
level = 1


---------------------------

---- GAME FUNCTIONS ----

local function changeLevelComplete()
	rRect:addEventListener( "tap", gFunc.tapListener )
	lRect:addEventListener( "tap", gFunc.tapListener )
	mRect:addEventListener( "tap", gFunc.tapListener )

	Runtime:addEventListener( "touch", gFunc.swipeListener )

	if(level == 2) then
		map = display.newImage(backGroup, "Sprites/map2.png", centerX, mapMarginY)
		mapClosed = display.newImage(backGroup, "Sprites/map2d.png", centerX, mapMarginY)
		mapOpened = display.newImage(backGroup, "Sprites/map2do.png", centerX, mapMarginY)
		doors = display.newImage(backGroup, "Sprites/doors.png", centerX, mapMarginY)
		currentMusic = lvl2Track
	else
		map = display.newImage(backGroup, "Sprites/map3.png", centerX, mapMarginY)
		mapClosed = display.newImage(backGroup, "Sprites/map3d.png", centerX, mapMarginY)
		mapOpened = display.newImage(backGroup, "Sprites/map3do.png", centerX, mapMarginY)
		doors = display.newImage(backGroup, "Sprites/doors.png", centerX, mapMarginY)
		currentMusic = lvl3Track
	end
	InitialAnimation()
end

local function changeLevelAnimation() --deleet dis
	--todo, change playerR position later
	playerObj:pause()
	playerObj:setSequence("walkingRight")
	playerObj:play()
	transition.to( playerObj, { time = 3500, x = (display.contentWidth + 20), onComplete = function() playerObj:pause() end} )
	-- transition.to( playerR, { delay=3250 , alpha = 1})
	-- transition.to( playerM, { delay=3500 , alpha = 0})
	transition.to( mapOpened, { delay = 3500, time = 2000, alpha = 0} )
	transition.to( map, { delay = 3500, time = 2000, alpha = 0} )
	--todo, working now, but needs tweaking in-game
	timer.performWithDelay(5500, function() changeLevelComplete() end, 1)
	--fadeout score and controlls
end

function changeLevel()
	--arrows stop and existing disappear
		--erase all arrows #IMPORTANT
		for i = #arrowTable, 1, -1 do
			display.remove( arrowTable[i] )
			table.remove( arrowTable, i )
		end
		--stop physics
		physics.pause()
		--stop arrow spawn
		timer.cancel(gameLoopTimer)
		--unable event listeners
		rRect:removeEventListener( "tap", gFunc.tapListener )
		lRect:removeEventListener( "tap", gFunc.tapListener )
		mRect:removeEventListener( "tap", gFunc.tapListener )

		Runtime:removeEventListener( "touch", gFunc.swipeListener )
	

end

--gameloop function will only run after the animation 
--will not run after player death
--todo, change checks from on colision to here
function gameLoop()
	if(onAnim == false and dead == false) then
		CreateArrows()
	end
	-- if(score >= 25 and level == 1) then
	-- 	--set to lvl 2, clear all arrows, make animations
	-- 	level = 2
	-- 	changeLevel()
	-- elseif(score >= 60 and level == 2) then
	-- 	--to lvl 3
	-- 	level = 3
	-- 	changeLevel()
	-- elseif(score == 100) then
	-- 	--AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	-- 	--end main game
	-- end
end

function endGame()
	--setting the game over score and going to the highscores page
	audio.stop(1)
  backgroundMusic = audio.loadStream("Sounds/Death.ogg")
  audio.play( backgroundMusic, { channel=1, loops=-1}  )
	timer.performWithDelay( 1000, composer.setVariable( "finalScore", score ))
	transition.to(playerObj, {time=800, alpha = 0})
  composer.gotoScene( "highscores", { time=800, effect="crossFade" } )
  
end
--------------------

-- -----------------------------------------------------------------------------------
--
-- Scene event functions
--
-- -----------------------------------------------------------------------------------

-- create()
function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	--pause physics for loading
	physics.pause()
	
	--setting groups
	backGroup = display.newGroup()
  	sceneGroup:insert( backGroup )
  	itemGroup = display.newGroup()
  	sceneGroup:insert( itemGroup )
  	playerGroup = display.newGroup()
  	sceneGroup:insert( playerGroup )
  	uiGroup = display.newGroup()
  	sceneGroup:insert( uiGroup )

    --loading the background map and setting their layers
	map = display.newImage(backGroup, "Sprites/map.png", centerX, mapMarginY)
	mapClosed = display.newImage(backGroup, "Sprites/mapd.png", centerX, mapMarginY)
	mapOpened = display.newImage(backGroup, "Sprites/mapdo.png", centerX, mapMarginY)
	doors = display.newImage(backGroup, "Sprites/doors.png", centerX, mapMarginY)

	map.alpha = 1
	mapClosed.alpha = 0
	mapOpened.alpha = 1
	doors.alpha = 0

	----loading sheets
	--player
	local playerSheet = graphics.newImageSheet( "Sprites/player sheet.png", optionsPlayer )
	playerObj = display.newSprite(playerSheet, playerAnimation)
	playerObj.x = display.contentCenterX
	playerObj.y = playerMarginY
	playerObj.alpha = 0
	physics.addBody( playerObj, { isSensor=true, shape=playerHitbox } )
	playerObj.myName = "player"

	--shield
	local sheetShield = graphics.newImageSheet( "Sprites/shield.png", optionsShield )
	shieldMMarginY = playerObj.y - playerObj.contentHeight / 2
	--creating shield on the right place
	shieldM = display.newImage(itemGroup, sheetShield, 1 , centerX, shieldMMarginY)
	shieldL = display.newImage(itemGroup, sheetShield, 2 , centerX - 22, playerObj.y)
	shieldR = display.newImage(itemGroup, sheetShield, 2 , centerX + 25, playerObj.y)
	--adding their bodies
	physics.addBody( shieldM, {isSensor = true, shape=shieldMHitbox} )
	physics.addBody( shieldL, {isSensor = true, shape=shieldLHitbox} )
	physics.addBody( shieldR, {isSensor = true, shape=shieldRHitbox} )
	--setting colision names
	shieldM.myName = "shield"
	shieldL.myName = "shield"
	shieldR.myName = "shield"
	--making everything disappear to be loaded in the animation
	shieldM.alpha = 0
	shieldL.alpha = 0
	shieldR.alpha = 0

	--music set
	currentMusic = lvl1Track

	createUI()
end


-- show()
function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

	elseif ( phase == "did" ) then
		--starting the physics again
		physics.start()
		--starting the collisions
		Runtime:addEventListener( "collision", gFunc.onCollision )
		--starting the animation
		gFunc.InitialAnimation()
	end
end


-- hide()
function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)
		if(gameLoopTimer ~= nil) then
			timer.cancel( gameLoopTimer )
		end

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen
		--removing the listeners
		Runtime:removeEventListener( "collision", gFunc.onCollision )
		Runtime:removeEventListener( "touch", gFunc.swipeListener )
		--pausing the physics and the music
        physics.pause()
		--todo, probably need to dispose of player
        --removing the scene
        composer.removeScene( "gameEndless" )

	end
end


-- destroy()
function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view
end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene