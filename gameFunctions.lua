local gameFunctions = {};

local widget = require("widget")
local composer = require("composer")

function gameVarInit()
    
    --Groups
    backGroup = nil
    itemGroup = nil
    playerGroup = nil
    uiGroup = nil
    
    --dimens
    centerX = display.contentCenterX
    centerY = display.contentCenterY
    displayW = display.contentWidth
    displayH = display.contentHeight
    mapMarginY = centerY + 35
    playerMarginY = displayH - 80
    shieldMMarginY = nil
    shieldMHitbox = {8, -8, 0, 0, -8, -8}
    shieldLHitbox = {-8, 8, 0, 0, -8, -8}
    shieldRHitbox = {0, 0, 6, 6, 6, -6, 0, 0}
    playerHitbox = {-16, 16, 16, 16, 16, -16, -16, -16}
    arrowHitbox = {-15, 6, 10, 3, 10, -3, -15, -6}
    
    --player, shield and arrows - object vars
    playerObj = nil
    shieldM = nil
    shieldL = nil
    shieldR = nil
    arrowTable = {}
    
    --maps object vars
    map = nil
    mapClosed = nil
    mapOpened = nil
    doors = nil
    
    --ui vars
    hudScore = nil
    rRect = nil
    lRect = nil
    mRect = nil
    triangle = nil
    triangler = nil
    trianglel = nil
    
    levelTimeMultiplier = 12
    levelStarterTime = 1000 -- to 700
    levelStarterVelocity = 50 -- to 75
    gameLoopTimer = nil
    
    --music
    bgmTrack = nil
    currentMusic = nil
    --sfx
    shieldClang = audio.loadSound( "Effects/shield.wav" )
    deathSound = audio.loadSound( "Effects/death.wav" )
    
    --game specific vars
    dead = false
    onAnim = true
    score = 0
    isPaused = false
    
    local sM = nil
    local sL = nil
    local sR = nil
    
end

--controls
function keyListener (event)
    --player will only move if is not on animation and its not dead
    if (onAnim == false and dead == false) then
        if (event.keyName == "right") then
            --right
            frameChanger(0, 0, 1)
        elseif (event.keyName == "left") then
            --left
            frameChanger(0, 1, 0)
        elseif (event.keyName == "up") then
            --up
            frameChanger(1, 0, 0)
        end
    end
end

--function to create the "enemies"
function CreateArrows()
    
    gameLoopTimer._delay = (1 / math.sqrt((score / 10) + 1)) * (levelStarterTime * 2)
    
    newArrow = display.newImage(itemGroup, "Sprites/arrow.png")
    newArrow:scale(0.75, 0.75)
    table.insert(arrowTable, newArrow)
    physics.addBody(newArrow, "kinematic", {shape = arrowHitbox})
    newArrow.isBullet = true
    --randomizing where does the arrow come from (top, right, left)
    local whereFrom = math.random(3)
    local vel = (math.log(score + 2) / math.log(10)) * 15
    --setting the top arrow
    if (whereFrom == 1) then
        newArrow.myName = "arrowM"
        newArrow.x = centerX
        newArrow.y = centerY - 125
        newArrow.rotation = 90
        newArrow:setLinearVelocity(0, vel * 10)
        --setting the left arrow
    elseif (whereFrom == 2) then
        newArrow.myName = "arrowL"
        newArrow.x = centerX - 220
        newArrow.y = playerMarginY
        newArrow:setLinearVelocity(vel * 10, 0)
        --setting the right arrow
    else
        newArrow.myName = "arrowR"
        newArrow.x = centerX + 220
        newArrow.y = playerMarginY
        newArrow.rotation = 180
        newArrow:setLinearVelocity(-vel * 10, 0)
    end
end

--setting the time for the loop
local function StartLoop()
    gameLoopTimer = timer.performWithDelay(levelStarterTime, function() gameLoop() end, -1)
end

--start function, for changing the map and starting the game it self
function Start()
    mapOpened.alpha = 0
    transition.to(mapOpened, {time = 400, alpha = 0})
    transition.to(shieldM, {time = 200, alpha = 1})
    transition.to(mapClosed, {time = 400, alpha = 1})
    transition.to(doors, {time = 400, alpha = 1})
    timer.performWithDelay(400, function() StartLoop() end, 1)
    onAnim = false
    playerObj:pause()
    playerObj:setSequence("all")
end

--player animation entering the room
function InitialAnimation()
    onAnim = true
    -- hudScore.text = "Progress: 0%"
    playerObj.x = centerX
    playerObj.y = displayH + playerObj.contentHeight
    playerObj.alpha = 1
    local backgroundMusic = audio.loadStream(currentMusic)
    audio.setVolume(0, {channel = 1})
    audio.stop(1)
    bgmTrack = audio.play(backgroundMusic, {channel = 1, loops = -1})
    --making player enter the room
    transition.to(playerObj, {time = 2000, y = playerMarginY})
    timer.performWithDelay(2000, function() Start() end, 1)
    --fading-in the audio
    if(system.getPreference("app", "music", "boolean") ~= nil) then
        if(system.getPreference("app", "music", "boolean")) then
            audio.fade({channel = 1, time = 2000, volume = 1})
        else
            audio.setVolume(0, {channel = 1})
        end
    end
    if(system.getPreference("app", "music", "boolean") ~= nil) then
        if(system.getPreference("app", "music", "boolean")) then
            audio.fade({channel = 1, time = 2000, volume = 1})
        else
            audio.setVolume(0, {channel = 1})
        end
    end
    physics.start()
    playerObj:setSequence("walking")
    playerObj:play()
end

function stopArrows()
    for i = #arrowTable, 1, -1 do
        arrowTable[i]:setLinearVelocity(0, 0)
    end
end

function frameChanger (p1, p2, p3)
    --trasparency of the player and the shield
    --print(p1 .. p2 .. p3)
    if(p1 == 1)then
        playerObj:setFrame(1)
    elseif(p2 == 1)then
        playerObj:setFrame(5)
    elseif(p3 == 1)then
        playerObj:setFrame(6)
    else
        playerObj:setFrame(4)
        stopArrows()
    end
    shieldM.alpha = p1
    shieldL.alpha = p2
    shieldR.alpha = p3
end

function swipeListener (event)
    --player will only move if is not on animation and its not dead
    if (onAnim == false and dead == false) then
        --when the user lift the finger after the swipe
        if (event.phase == "ended") then
            if (event.xStart < event.x and (event.x - event.xStart) > (event.yStart - event.y)) then
                --left > right
                frameChanger(0, 0, 1)
            elseif (event.xStart > event.x and (event.xStart - event.x) > (event.yStart - event.y)) then
                --right > left
                frameChanger(0, 1, 0)
            else
                if(event.yStart - event.y > 0) then
                    --up
                    frameChanger(1, 0, 0)
                end
            end
        end
    end
end

function tapListener (event)
    --player will only move if is not on animation and its not dead
    if (onAnim == false and dead == false) then
        if (event.target.id == 1) then
            --right
            frameChanger(0, 0, 1)
        elseif (event.target.id == 2) then
            --left
            frameChanger(0, 1, 0)
        else
            --up
            frameChanger(1, 0, 0)
        end
    end
end

function moveShield(objA, objS)
    if (objA.myName == "arrowM") then
        --move shield down
        playerObj:setFrame(2)
        transition.to(objS, {time = 100, y = playerMarginY - 18, onComplete = function() transition.to(objS, {y = playerMarginY - 20}) playerObj:setFrame(1) end})
    elseif (objA.myName == "arrowL") then
        --move left shield
        playerObj:setFrame(7)
        transition.to(objS, {time = 100, x = centerX - 20, onComplete = function() transition.to(objS, {x = centerX - 22}) playerObj:setFrame(5) end})
    else
        --move right shield
        --shieldR.x = centerX + 25
        playerObj:setFrame(8)
        transition.to(objS, {time = 100, x = centerX + 23, onComplete = function() transition.to(objS, {x = centerX + 25}) playerObj:setFrame(6) end})
    end
end

function onCollision(event)
    if (event.phase == "began") then
        local obj1 = event.object1
        local obj2 = event.object2
        --these arrow-shields ifs test if the shield protected the player from the arrow
        --todo, change names to something simpler
        if ((obj1.myName == "arrowM" or obj1.myName == "arrowL" or obj1.myName == "arrowR") and obj2.myName == "shield" and obj2.alpha == 1) then
            moveShield(obj1, obj2)
            audio.play(shieldClang, {channel = 2})
            display.remove(obj1)
            score = score + 1
            if(composer.getSceneName("current") == "game") then
                hudScore.text = "Progress: " .. math.round(((score / toNextLevelScore) * 100) * 10) * .1 .. "%"
            else
                hudScore.text = "score: " .. score
            end
            for i = #arrowTable, 1, -1 do
                if (arrowTable[i] == obj1) then
                    table.remove(arrowTable, i)
                    break
                end
            end
        elseif (obj1.myName == "shield" and (obj2.myName == "arrowM" or obj2.myName == "arrowL" or obj2.myName == "arrowR") and obj1.alpha == 1) then
            moveShield(obj2, obj1)
            audio.play(shieldClang, {channel = 2})
            display.remove(obj2)
            score = score + 1
            if(composer.getSceneName("current") == "game") then
                hudScore.text = "Progress: " .. math.round(((score / toNextLevelScore) * 100) * 10) * .1 .. "%"
            else
                hudScore.text = "score: " .. score
            end
            for i = #arrowTable, 1, -1 do
                if (arrowTable[i] == obj2) then
                    table.remove(arrowTable, i)
                    break
                end
            end
            --and these arrow-player tell the game that an arrow has killed the player
        elseif ((obj1.myName == "arrowM" or obj1.myName == "arrowL" or obj1.myName == "arrowR") and obj2.myName == "player" and dead == false) then
            frameChanger(0, 0, 0)
            dead = true
            audio.play(deathSound, {channel = 2})
            endGame()
        elseif (obj1.myName == "player" and (obj2.myName == "arrowM" or obj2.myName == "arrowL" or obj2.myName == "arrowR") and dead == false) then
            frameChanger(0, 0, 0)
            dead = true
            audio.play(deathSound, {channel = 2})
            endGame()
        end
    end
end

function pauseGame(event)
    if event.phase == "began" then
        if (onAnim == false and dead == false and gameLoopTimer ~= nil) then
            pauseButton:removeEventListener("tap", pauseGame)
            if isPaused == false then
                Runtime:removeEventListener("collision", onCollision)
                Runtime:removeEventListener("touch", swipeListener)
                rRect:removeEventListener("tap", tapListener)
                lRect:removeEventListener("tap", tapListener)
                mRect:removeEventListener("tap", tapListener)
                physics.pause()
                timer.pause(gameLoopTimer)
                audio.setVolume(0, {channel = 1})
                composer.showOverlay("pause", {isModal = false})
                isPaused = true
            elseif isPaused == true then
                composer.hideOverlay(0)
                physics.start()
                Runtime:addEventListener("collision", onCollision)
                timer.resume(gameLoopTimer)
                isPaused = false
                commitPauseSettings()
            end
            pauseButton:addEventListener("tap", pauseGame)
        end
    end
end

--todo: implement audio
function commitPauseSettings()
    
    --test if player set sound to on or off and commits it
    if (system.getPreference("app", "sound", "boolean") ~= nil) then
        if(system.getPreference("app", "sound", "boolean")) then
            audio.setVolume(1, {channel=2})
        else
            audio.setVolume(0, {channel=2})
        end
    end
    --test if player set music to on or off and commits it
    if(system.getPreference("app", "music", "boolean") ~= nil) then
        if(system.getPreference("app", "music", "boolean")) then
            audio.setVolume(.5, {channel = 1})
        else
            audio.setVolume(0, {channel = 1})
        end
    end
    --test if player set to use swipe or arrowkeys and makes the right visual effects and listeninig
    if(system.getPreference("app", "swipe", "boolean") ~= nil) then
        if(system.getPreference("app", "swipe", "boolean"))then
            triangle.alpha = 0.5
            mRect.alpha = 0.1
            trianglel.alpha = 0.5
            lRect.alpha = 0.1
            triangler.alpha = 0.5
            rRect.alpha = 0.1
            rRect:addEventListener("tap", tapListener)
            lRect:addEventListener("tap", tapListener)
            mRect:addEventListener("tap", tapListener)
            Runtime:removeEventListener("touch", swipeListener)
        else
            triangle.alpha = 0
            mRect.alpha = 0
            trianglel.alpha = 0
            lRect.alpha = 0
            triangler.alpha = 0
            rRect.alpha = 0
            rRect:removeEventListener("tap", tapListener)
            lRect:removeEventListener("tap", tapListener)
            mRect:removeEventListener("tap", tapListener)
            Runtime:addEventListener("touch", swipeListener)
        end
    end
    
end

function createUI()
    --rectangle in the top
    topRect = display.newRect(uiGroup, centerX, 0, displayW, 0)
    paint = {0.62, 0.62, 0.62}
    topRect.alpha = 0.65
    topRect.fill = paint
    
    --Score hud element
    hudScore = display.newText(uiGroup, "score: " .. score, 0, 0, "Kenney Pixel.ttf", 32)
    hudScore.x = hudScore.contentWidth
    hudScore.y = hudScore.contentHeight
    hudScore:setFillColor(0, 0, 0)
    --setting the rectangle the correct size
    topRect.height = hudScore.contentHeight * 2
    topRect.y = topRect.contentHeight / 2
    
    ----CONTROLS---------------------
    --setting the touch controlls
    rRect = display.newRect(uiGroup, centerX + 80, centerY, 50, 50)
    lRect = display.newRect(uiGroup, centerX - 80, centerY, 50, 50)
    mRect = display.newRect(uiGroup, centerX, centerY, 50, 50)
    paddingRect = mRect.contentWidth
    
    rRect.x = displayW - rRect.contentWidth / 2 - paddingRect
    rRect.y = displayH - rRect.contentHeight
    rRect.alpha = 0.1
    lRect.x = displayW - lRect.contentWidth * 2.5 - paddingRect
    lRect.y = displayH - lRect.contentHeight
    lRect.alpha = 0.1
    mRect.x = displayW - mRect.contentWidth * 1.5 - paddingRect
    mRect.y = displayH - mRect.contentHeight * 2
    mRect.alpha = 0.1
    rRect.id = 1
    lRect.id = 2
    mRect.id = 0
    
    triangle = display.newImage(uiGroup, "./Sprites/upArrow.png", mRect.x, mRect.y)
    triangle:scale(0.5, 0.5)
    triangle.alpha = 0.5
    triangler = display.newImage(uiGroup, "./Sprites/rightArrow.png", rRect.x, rRect.y)
    triangler:scale(0.5, 0.5)
    triangler.alpha = 0.5
    trianglel = display.newImage(uiGroup, "./Sprites/leftArrow.png", lRect.x, lRect.y)
    trianglel:scale(0.5, 0.5)
    trianglel.alpha = 0.5
    
    --pause button
    --   pauseButton = widget.newButton(
    --   {
    --   x = display.contentWidth-25,
    --   y = 25,
    --   width = 50,
    --       height = 50,
    --       defaultFile = "Sprites/button.png",
    --       overFile = "Sprites/button_pressed.png",
    --   label = "P",
    --   font = "Kenney Pixel.ttf",
    --   fontSize = 35,
    --   labelColor = { default = {0.49, 0.43, 0.27}, over = {0.63, 0.55, 0.36}},
    --   labelYOffset = -4,
    --     onEvent = pauseGame
    --   }
    --   )
    pauseButton = widget.newButton(
        {
            x = display.contentWidth - 25,
            y = 25,
            width = 40,
            height = 40,
            defaultFile = "Sprites/pauseButton.png",
            onEvent = pauseGame
        })
        pauseButton:setFillColor(0.63, 0.55, 0.36)
        uiGroup:insert(pauseButton)
        
        --adding the event listeners for all the controlls
        rRect:addEventListener("tap", tapListener)
        lRect:addEventListener("tap", tapListener)
        mRect:addEventListener("tap", tapListener)
        
        Runtime:addEventListener("touch", swipeListener)
        
        pauseButton:addEventListener("tap", pauseGame)
        
        --everytime it builds the scene it test the user pause-menu-settings
        commitPauseSettings()
    end
    
    --declaring functions publicly
    gameFunctions.frameChanger = frameChanger
    gameFunctions.swipeListener = swipeListener
    gameFunctions.tapListener = tapListener
    gameFunctions.onCollision = onCollision
    gameFunctions.gameVarInit = gameVarInit
    gameFunctions.keyListener = keyListener
    gameFunctions.CreateArrows = CreateArrows
    gameFunctions.InitialAnimation = InitialAnimation
    gameFunctions.Start = Start
    
    return gameFunctions
    