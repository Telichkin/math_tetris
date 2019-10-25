local composer = require("composer")
local widget = require("widget")
local tasks = require("lib.tasks")
local utils = require("lib.utils")
local state = require("lib.state")
local sound = require("lib.sound")
local inputReader = require("lib.inputReader")
local saver = require("lib.saver")


------------------
-- Конфигурация --
------------------
local mainFont = "assets/Neucha-Regular"

local numberOfBoxesW = 3
local numberOfBoxesH = 10

local fieldW = display.contentWidth * 0.92
local fieldH = display.contentHeight * 0.85

local boxMarginX = 1
local boxMarginY = 1
local boxRadius = 0
local boxWidth = fieldW / numberOfBoxesW - (2 * boxMarginX)
local boxHeight = fieldH / numberOfBoxesH - 5
local boxXPositions = {-(boxMarginX * 1.5 + boxWidth), 0, (boxMarginX * 1.5 + boxWidth)}
local startY = ((boxHeight - fieldH) / 2) - ((boxHeight + boxMarginY) * 1.5)

local heartH = (display.contentHeight - fieldH) * 0.5 * 0.6
local heartStartX = display.contentCenterX - (fieldW / 2) + (heartH / 2)
local heartStartY = display.contentCenterY - (display.contentHeight / 2) + ((display.contentHeight - fieldH) / 4)

local modalW = display.contentWidth * 0.85
local modalH = display.contentHeight * 0.6
local modalStartY = - (modalH / 2) - ((display.actualContentHeight - display.contentHeight) / 2)

local maxLives = 3
local maxPositionY = {display.contentHeight, display.contentHeight, display.contentHeight}

----------------------------------
-- Глобальное состояние рендера --
----------------------------------
local scene = composer.newScene()
local gameGroup
local mainGroup
local modalWindow
local opacityGroup
local livesGroup
local activeBoxR
local staticBoxesR = {{}, {}, {}}

local uiEvent

-------------------------------
-- Глобальное состояние игры --
-------------------------------
local currS = {
  isInited = false,
  isVisible = false,
  isPaused = false,
  result = nil,
  lives = maxLives,
  -- boxes
  active = nil,
  static = {{}, {}, {}},  -- Каждый массив -- это колонка на игровом поле
}
local prevS = utils.deepCopy(currS)

-----------------------------
-- Вспомогательные функции --
-----------------------------
local function last(arr)
  return arr[#arr]
end


local function createMainGroup()
  mainGroup = display.newGroup()
  scene.view:insert(mainGroup)
  local background = display.newRect(
    mainGroup, display.contentCenterX, display.contentCenterY, 
    display.actualContentWidth, display.actualContentHeight
  )
  background:setFillColor(utils.rgb(97, 134, 232, 1))
end


local function createGameGroup()
  gameGroup = display.newContainer(fieldW, fieldH)
  gameGroup.x = display.contentCenterX
  gameGroup.y = display.contentCenterY
  mainGroup:insert(gameGroup)
  local background = display.newRect(gameGroup, 0, 0, gameGroup.width, gameGroup.height)
  background:setFillColor(1, 1, 1)
end


local function createBackBtn()
  local btn = display.newGroup()
  btn.x = display.contentCenterX
  btn.y = display.contentCenterY + ((display.actualContentHeight - fieldH) / 4) + (fieldH / 2)

  local shape = display.newRect(btn, 0, 0, 100, 30)
  shape:setFillColor(utils.rgb(97, 134, 232, 1))
  shape.strokeWidth = 2
  shape:setStrokeColor(1, 1, 1, 1)

  display.newText(btn, "назад", 0, 0, mainFont, 25)
  mainGroup:insert(btn)

  btn:addEventListener("tap", function ()
    uiEvent = "Back"
    sound.play("tap")
  end)
end


local function createModalWindow(titleText, personaImg, secondaryBtn, mainBtn)
  opacityGroup = display.newRect(
    display.contentCenterX, display.contentCenterY, 
    display.actualContentWidth, display.actualContentHeight
  )
  opacityGroup:setFillColor(0, 0, 0)
  opacityGroup.alpha = 0
  mainGroup:insert(opacityGroup)

  modalWindow = display.newGroup()
  modalWindow.x = display.contentCenterX
  modalWindow.y = modalStartY

  local background = display.newRect(modalWindow, 0, 0, modalW, modalH)
  background:setFillColor(utils.rgb(255, 255, 255, 1))
  background.strokeWidth = 4
  background:setStrokeColor(utils.rgb(149, 175, 237))

  local title = display.newText(
    modalWindow, titleText,
    0, -(modalH / 2) + 40,
    mainFont, 25
  )
  title:setFillColor(utils.rgb(0, 0, 0))

  local persona = display.newImage(modalWindow, "assets/images/" .. personaImg, 0, -30)
  local pW, pH = persona.width, persona.height
  persona.height = modalH * 0.36
  persona.width = persona.height / pH * pW

  local toMenu = display.newText(
    modalWindow, secondaryBtn[1], 
    0, persona.y + (persona.height / 2) + 25, 
    mainFont, 21)
  toMenu:setFillColor(utils.rgb(0, 0, 0))

  toMenu:addEventListener("tap", function ()
    secondaryBtn[2]()
    sound.play("tap")
  end)

  local btnGroup = display.newGroup()
  local btn = display.newRect(btnGroup, 0, 0, modalW * 0.6, 70)
  btn:setFillColor(utils.rgb(255, 255, 255))
  btn.strokeWidth = 3
  btn:setStrokeColor(utils.rgb(56, 102, 204))

  local btnText = display.newText({
    parent = btnGroup, 
    text = mainBtn[1], 
    x = 0, 
    y = 0, 
    font = mainFont, 
    fontSize = 25,
    align = "center",
  })
  btnText:setFillColor(utils.rgb(0, 0, 0))
  btnGroup.x = 0
  btnGroup.y = (modalH / 2) - 50
  modalWindow:insert(btnGroup)
  mainGroup:insert(modalWindow)

  btnGroup:addEventListener("tap", function ()
    mainBtn[2]()
    sound.play("tap")
  end)
  opacityGroup:addEventListener("tap", function () return true end)

  transition.to(modalWindow, {time = 1200, y = display.contentCenterY, transition = easing.outExpo})
  transition.to(opacityGroup, {time = 500, alpha = 0.5})
end


local function createBox(b)
  box = display.newGroup()
  gameGroup:insert(box)
  -- У нас 14 разных типа изображений блоков
  local name = "block-" .. tostring(math.random(14)) .. ".png"
  local shape = display.newImageRect(box, "assets/images/" .. name, boxWidth, boxHeight)
  
  text = display.newText(box, b.task.text, 0, 0, mainFont, 17)
  text:setFillColor(0, 0, 0)

  box.y = b.y
  box.x = boxXPositions[b.col]
  return box
end


local function createLivesGroup()
  livesGroup = display.newGroup()
  livesGroup.y = heartStartY
  livesGroup.x = heartStartX
  mainGroup:insert(livesGroup)
  for i = 1, maxLives do
    local shape = display.newImageRect(
      livesGroup,
      currS.lives >= i and "assets/images/heart_full.png" or "assets/images/heart.png",
      heartH, heartH
    )
    shape.x = ((i - 1) * (heartH + 5))
    shape.y = 0
  end
end

---------------
-- Game Loop --
---------------
local lastTickMs = 0
local function tick(event)
  -- Сколько прошло с предыдущего тика
  if not currS.isInited then lastTickMs = event.time end

  local ms = event.time
  local deltaMs = ms - lastTickMs
  lastTickMs = ms

  -----------------------------------
  -- Сохранение прошлого состояния --
  -----------------------------------
  prevS = utils.deepCopy(currS)

  --------------------
  -- Чтение инпута  --
  --------------------
  local lastEvent = inputReader.getLastEvent()

  --------------------------
  -- Обновление состояния --
  --------------------------
  if uiEvent == "Back" then
    currS.isPaused = true
  elseif uiEvent == "Continue" then
    currS.isPaused = false
  end

  local lvlTasks, lvlNumbers = state.lvl.lvlTasks, state.lvl.lvlNumbers
  local scheme = state.lvl.scheme
  local lazyLoaded = lvlTasks ~= nil and lvlNumbers ~= nil and scheme ~= nil

  if currS.result == nil and currS.isPaused == false and lazyLoaded == true then
    -- Инициализация
    if currS.isInited == false then
      for col = 1, 3 do
        for row = 1, #scheme[col] do
          local type = scheme[col][row]
          if type == "task" or type == "number" then
            currS.static[col][row] = {
              col = col,
              y = (fieldH / 2) - ((row - 1) * (boxHeight + boxMarginY)) - (boxHeight / 2 + boxMarginY),
              task = tasks.createOne(lvlTasks, lvlNumbers, false, type, last(currS.static[col])),
              speed = 0,
            }
          end
        end
      end
      currS.isInited = true
    end

    if currS.active == nil and currS.isInited == true then
      currS.active = {
        col = math.random(3),
        y = startY,
        task = tasks.createOne(lvlTasks, lvlNumbers, true, nil, last(currS.static[1]), last(currS.static[2]), last(currS.static[3])),
        speed = 1,
      }
    end

    -- Игра
    if currS.isVisible == true then
      local prevCol = currS.active.col
      if lastEvent == "Swipe Left" then
        currS.active.col = (currS.active.col - 1 < 1) and 1 or currS.active.col - 1
      elseif lastEvent == "Swipe Right" then
        currS.active.col = (currS.active.col + 1 > 3) and 3 or currS.active.col + 1
      elseif lastEvent == "Swipe Down" then
        currS.active.speed = 12
      elseif lastEvent == "Swipe Up" then
        currS.active.speed = -12
      end

      currS.active.y = currS.active.y + (currS.active.speed * deltaMs / 25)

      local nearBox = last(currS.static[currS.active.col])
      local maxY = (nearBox and nearBox.y - (boxHeight + boxMarginY)) or ((fieldH / 2) - (boxHeight / 2 + boxMarginY))
      if currS.active.y >= maxY then
        -- Столкновение с другим боксом по горизонтали
        if prevCol ~= currS.active.col then
          currS.active.col = prevCol
        -- Столкновение с другим боксом по вертикали
        else
          if not tasks.isSolved(nearBox, currS.active) then 
            currS.lives = currS.lives - 1 
          elseif nearBox then
            table.remove(currS.static[nearBox.col], #currS.static[nearBox.col])
          end
          currS.active = nil
        end
      -- Улетел вверх
      elseif currS.active.y < startY then
        -- Проверяем, есть ли на поле правильно решение. Если есть, то игрок зря смахнул блок вверх. и мы отнимаем
        -- у игрока жизнь
        local b1, b2, b3 = last(currS.static[1]), last(currS.static[2]), last(currS.static[3]) 
        if (tasks.isSolved(b1, currS.active) or tasks.isSolved(b2, currS.active) or tasks.isSolved(b3, currS.active)) then
          currS.lives = currS.lives - 1
        end
        currS.active = nil
      end
      
      -- Проиграл
      if currS.lives == 0 then
        currS.result = "lose"
      end

      -- Победил, если поле осталось чистым
      if (not last(currS.static[1])) and (not last(currS.static[2])) and (not last(currS.static[3])) then
        currS.result = "win"
      end
    end

    uiEvent = nil
  end

  ---------------
  -- Рендеринг --
  ---------------
  -- Если игра была только что проинициализирована, то можем создать все графические объекты:
  --  * игровое поле
  --  * статические блоки
  --  * активный блок
  --  * жизни
  -- 
  -- Эти объекты не будут пересоздаваться на каждом кадре
  if prevS.isInited == false and currS.isInited == true then
    createMainGroup()
    createBackBtn()
    createGameGroup()
    createLivesGroup()
    activeBoxR = createBox(currS.active)
    for i, col in pairs(currS.static) do
      for j, box in pairs(col) do
        staticBoxesR[i][j] = createBox(box)
      end
    end
  end
  
  -- Уменьшились жизни
  if prevS.lives > currS.lives then
    display.remove(livesGroup)
    createLivesGroup()
  end

  -- Хочет выйти
  if prevS.isPaused == false and currS.isPaused == true then
    createModalWindow(
      "Хочешь выйти из игры?",
      "exit.png",
      {"Выйти", function ()
        composer.gotoScene("scenes.levels", {time = 450, effect = "slideRight"})
      end},
      {"Продолжить\nигру", function ()
        transition.to(modalWindow, {time = 500, y = modalStartY, transition = easing.inSine, onComplete = function ()
          display.remove(modalWindow)
        end})
        transition.fadeOut(opacityGroup, {time = 500, onComplete = function ()
          display.remove(opacityGroup)
          uiEvent = "Continue"
        end})
      end}
    )
  end

  -- Победа
  if prevS.result ~= "win" and currS.result == "win" then
    createModalWindow(
      "Уровень пройден!", 
      "win.jpg",
      {"Меню", function ()
        composer.gotoScene("scenes.levels", {time = 450, effect = "slideRight"})
      end},
      {"Следующий\nуровень", function ()
        state.lvl = utils.nextLvl(state.lvl)
        composer.gotoScene("scenes.loading")
      end}
    )
  end

  -- Поражение
  if prevS.result ~= "lose" and currS.result == "lose" then
    createModalWindow(
      "Попробуй ещё раз", 
      "lose.jpg",
      {"Меню", function ()
        composer.gotoScene("scenes.levels", {time = 450, effect = "slideRight"})
      end},
      {"Играть\nснова", function ()
        composer.gotoScene("scenes.loading")
      end}
    )
  end

  -- Активный блок появился
  if prevS.active == nil and currS.active ~= nil then
    activeBoxR = createBox(currS.active)
  end

  -- Активный блок исчез
  if prevS.active ~= nil and currS.active == nil then
    -- В какой колонке был активный блок в момент исчезновения
    local col = prevS.active.col
    
    local activeBoxRToDelete = activeBoxR
    -- Если блок летел вниз, то нужно приблизить его максимально близко к нижнему блоку
    if prevS.active.speed > 0 then
      local lowerBox = last(prevS.static[col])
      local lowerBoxY = lowerBox and lowerBox.y or ((fieldH / 2) + (boxHeight / 2))
      activeBoxRToDelete.y = lowerBoxY - boxHeight - boxMarginY
    end

    transition.to(activeBoxRToDelete, {
      alpha = 0,
      time = 200,
      onComplete = function ()
        display.remove(activeBoxRToDelete)
      end
    })

    -- При исчезновении уничтожил статический блок
    if #prevS.static[col] ~= #currS.static[col] then
      local staticBoxRToDelete = table.remove(staticBoxesR[col], #staticBoxesR[col])
      transition.to(staticBoxRToDelete, {
        alpha = 0,
        time = 200,
        onComplete = function ()
          display.remove(staticBoxRToDelete)
        end
      })
    end
  end

  if currS.active then
    activeBoxR.y = currS.active.y
    activeBoxR.x = boxXPositions[currS.active.col]
  end

  ----------
  -- Звук --
  ----------
  -- Свайпнули активный блок
  if prevS.active and currS.active then
    if (prevS.active.col ~= currS.active.col) then  -- По-горизонтали
      sound.play("swipe_2")
    elseif (prevS.active.speed ~= currS.active.speed) then  -- По-вертикали
      sound.play("swipe_1")
    end
  end

  -- Активный блок исчез
  if prevS.active ~= nil and currS.active == nil then
    -- Столкнувшись с другим блоком по-вертикали (то есть не улетел вверх)
    if prevS.active.speed > 0 then
      sound.play("impact")
    end
  end

  -- Победа
  if prevS.result ~= "win" and currS.result == "win" then
    sound.play("win")
  end

  -- Поражение
  if prevS.result ~= "lose" and currS.result == "lose" then
    sound.play("lose")
  end


  ----------------
  -- Сохранение --
  ----------------
  if prevS.result ~= "win" and currS.result == "win" then
    saver.saveLvl(utils.nextLvlIndex(state.lvl))
  end
end


function scene:show(event)
  if event.phase == "will" then
    tick({time = 0})  -- Инициализируем состояние в первом тике
  elseif event.phase == "did" then
    Runtime:addEventListener("enterFrame", tick)
    timer.performWithDelay(500, function () currS.isVisible = true end)
  end
end


function scene:hide(event) 
  if event.phase == "will" then
    Runtime:removeEventListener("enterFrame", tick)
    composer.removeScene("scenes.game")
  end
end


scene:addEventListener("show")
scene:addEventListener("hide")

return scene