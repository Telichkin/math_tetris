local composer = require("composer")
local widget = require("widget")
local tasks = require("lib.tasks")
local utils = require("lib.utils")
local state = require("lib.state")
local inputReader = require("lib.inputReader")

-- Нужна другая механика
-- Что-то вроде волн: сверху появляется "волна" из трех задач и игрок должен указать в какую задачу
-- он "швырнет" решение.
-- если решение неправильное, то появляется новая волна или снимается жизнь.
-- волны идут с постоянной скоростью



------------------
-- Конфигурация --
------------------
local mainFont = "assets/Neucha-Regular"

local numberOfBoxesW = 3
local numberOfBoxesH = 12

local fieldW = display.contentWidth * 0.92
local fieldH = display.contentHeight * 0.85

local boxMarginX = 1
local boxMarginY = 2
local boxRadius = 0
local boxWidth = fieldW / numberOfBoxesW - 2 * boxMarginX
local boxHeight = fieldH / numberOfBoxesH - 5
local boxXPositions = {-(boxMarginX * 1.5 + boxWidth), 0, (boxMarginX * 1.5 + boxWidth)}
local startY = ((boxHeight - fieldH) / 2) - ((boxHeight + boxMarginY) * 1.5)

local heartH = (display.contentHeight - fieldH) * 0.5 * 0.6
local heartStartX = display.contentCenterX - (fieldW / 2) + (heartH / 2)
local heartStartY = display.contentCenterY - (display.contentHeight / 2) + ((display.contentHeight - fieldH) / 4)

local maxLives = 3

--------------------------
-- Глобальное состояние --
--------------------------
local scene = composer.newScene()
local gameGroup
local mainGroup
local gameOverGroup
local livesGroup

local gameInited = false
local gameIsOver = false
local gameResult = "idle"
local lastTickMs = 0
local lives = maxLives
local activeBox = nil
-- Каждый массив -- это колонка на игровом поле
local staticBoxes = {{}, {}, {}}
local maxPositionY = {display.contentHeight, display.contentHeight, display.contentHeight}
local lvlTasks, lvlNumbers = {}, {}


-----------------------------
-- Вспомогательные функции --
-----------------------------
local function gotoMenu()
  composer.gotoScene("scenes.menu")
end


local function last(arr)
  return arr[#arr]
end


local function createMainGroup()
  mainGroup = display.newGroup()
  scene.view:insert(mainGroup)
  local background = display.newRect(mainGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight)
  background:setFillColor(utils.rgb(97, 134, 232, 1))
end


local function createGameGroup()
  gameGroup = display.newContainer(fieldW, fieldH)
  gameGroup.x = display.contentCenterX
  gameGroup.y = display.contentCenterY
  scene.view:insert(gameGroup)
  local background = display.newRoundedRect(gameGroup, 0, 0, gameGroup.width, gameGroup.height, 0)
  background:setFillColor(1, 1, 1)
end


local function createGameOverBackground()
  gameOverGroup = display.newGroup()
  gameOverGroup.x = display.contentCenterX
  gameOverGroup.y = display.contentCenterY
  local opacity = display.newRect(gameOverGroup, 0, 0, display.contentWidth, display.contentHeight)
  opacity:setFillColor(utils.rgb(0, 0, 0, 0.5))

  local W, H = mainGroup.width * 0.85, mainGroup.height * 0.7
  local background = display.newRect(gameOverGroup, 0, 0, W, H)
  background:setFillColor(utils.rgb(255, 255, 255, 1))
  background.strokeWidth = 4
  background:setStrokeColor(utils.rgb(149, 175, 237))

  local title = display.newText(
    gameOverGroup, 
    gameResult == "win" and "Уровень пройден!" or "Попробуй ещё раз",
    0,
    - (H / 2) + 40,
    mainFont, 27
  )
  title:setFillColor(utils.rgb(0, 0, 0))

  local persona = display.newImage(
    gameOverGroup,
    "assets/images/" .. (gameResult == "win" and "win" or "lose") .. ".jpg",
    0, -30
  )
  local pW, pH = persona.width, persona.height
  persona.height = H * 0.36
  persona.width = persona.height / pH * pW

  local toMenu = display.newText(gameOverGroup, "Меню", 0, persona.y + (persona.height / 2) + 35, mainFont, 27)
  toMenu:setFillColor(utils.rgb(0, 0, 0))

  toMenu:addEventListener("tap", gotoMenu)

  local btnGroup = display.newGroup()
  local btn = display.newRect(btnGroup, 0, 0, W * 0.6, 70)
  btn:setFillColor(utils.rgb(255, 255, 255))
  btn.strokeWidth = 3
  btn:setStrokeColor(utils.rgb(56, 102, 204))

  local btnText = display.newText({
    parent = btnGroup, 
    text = gameResult == "win" and "Следующий\nуровень" or "Играть\nснова", 
    x = 0, 
    y = 0, 
    font = mainFont, 
    fontSize = 26,
    align = "center",
  })
  btnText:setFillColor(utils.rgb(0, 0, 0))
  btnGroup.x = 0
  btnGroup.y = (H / 2) - 50
  gameOverGroup:insert(btnGroup)
  scene.view:insert(gameOverGroup)

  btnGroup:addEventListener("tap", function ()
    if gameResult == "win" then
      state.lvl = utils.nextLvl(state.lvl)
    end
    composer.gotoScene("scenes.toGame")
  end)
end


local function createBox(b)
  box = display.newGroup()
  gameGroup:insert(box)
  
  -- у нас три разных типа изображений блоков
  local name = "block-" .. tostring(math.random(3)) .. ".png"
  local shape = display.newImageRect(box, "assets/images/" .. name, boxWidth, boxHeight)
  text = display.newText(box, "", 0, 0, mainFont, 17)
  text:setFillColor(0, 0, 0)

  box.y = b.y
  box.x = boxXPositions[b.col]

  if (b.task.type == "number") then
    text.text = tostring(b.task.n)
  else
    text.text = b.task.type:gsub("a", b.task.a):gsub("b", b.task.b)
  end

  b.view = box
  return b
end


local function createLivesGroup()
  livesGroup = display.newGroup()
  livesGroup.y = heartStartY
  livesGroup.x = heartStartX
  mainGroup:insert(livesGroup)
  for i = 1, lives do
    local shape = display.newImageRect(livesGroup, "assets/images/heart.png", heartH, heartH)
    shape.x = ((i - 1) * (heartH + 5))
    shape.y = 0
  end
end

---------------
-- Game Loop --
---------------
local function tick(event)
  -- Сколько прошло с предыдущего тика
  if not gameInited then lastTickMs = event.time end

  local ms = event.time
  local deltaMs = ms - lastTickMs
  lastTickMs = ms

  --------------------
  -- Чтение инпута  --
  --------------------
  local lastEvent = inputReader.getLastEvent()

  --------------------------
  -- Обновление состояния --
  --------------------------
  if not gameIsOver then
    if not gameInited then
      lvlTasks, lvlNumbers = tasks.generate(state.lvl.task, state.lvl.limit)
      local scheme = state.lvl.scheme

      for row = 1, #scheme do
        for col = 1, 3 do
          local type = scheme[row][col]
          if type == "task" or type == "number" then
            staticBoxes[col][row] = createBox({
              col = col, 
              y = (fieldH / 2) - ((row - 1) * (boxHeight + boxMarginY)) - (boxHeight / 2 + boxMarginY),
              task = tasks.createOne(lvlTasks, lvlNumbers, false, type, last(staticBoxes[col])),
              speed = 0,
            })
          end
        end
      end
      gameInited = true
    end

    if activeBox == nil then
      activeBox = createBox({
        col = math.random(3),
        y = startY,
        task = tasks.createOne(lvlTasks, lvlNumbers, true, nil, last(staticBoxes[1]), last(staticBoxes[2]), last(staticBoxes[3])),
        speed = 1,
      })
    end

    local prevCol = activeBox.col
    if lastEvent == "Swipe Left" then
      activeBox.col = (activeBox.col - 1 < 1) and 1 or activeBox.col - 1
    elseif lastEvent == "Swipe Right" then
      activeBox.col = (activeBox.col + 1 > 3) and 3 or activeBox.col + 1
    elseif lastEvent == "Swipe Down" then
      activeBox.speed = 12
    elseif lastEvent == "Swipe Up" then
      activeBox.speed = -12
    end

    activeBox.y = activeBox.y + (activeBox.speed * deltaMs * 20 / display.contentHeight)

    local nearBox = last(staticBoxes[activeBox.col])
    local maxY = (nearBox and nearBox.y - (boxHeight + boxMarginY)) or ((fieldH / 2) - (boxHeight / 2 + boxMarginY))
    if activeBox.y >= maxY then
      -- Столкновение с другим боксом по горизонтали
      if prevCol ~= activeBox.col then
        activeBox.col = prevCol
      -- Столкновение с другим боксом по вертикали
      else
        if not tasks.isSolved(nearBox, activeBox) then 
          lives = lives - 1 
        elseif nearBox then
          table.remove(staticBoxes[nearBox.col], #staticBoxes[nearBox.col])
          display.remove(nearBox.view)
        end

        display.remove(activeBox.view)
        activeBox = nil
      end
    -- Улетел вверх
    elseif activeBox.y < startY then
      -- Проверяем, есть ли на поле правильно решение. Если есть, то игрок зря смахнул блок вверх. и мы отнимаем
      -- у игрока жизнь
      local b1, b2, b3 = last(staticBoxes[1]), last(staticBoxes[2]), last(staticBoxes[3]) 
      if (tasks.isSolved(b1, activeBox) or tasks.isSolved(b2, activeBox) or tasks.isSolved(b3, activeBox)) then
        lives = lives - 1
      end
      display.remove(activeBox.view)
      activeBox = nil
    end
    
    -- Проиграл
    if lives == 0 then
      gameIsOver = true
      gameResult = "lose"
    end

    -- Победил, если поле осталось чистым
    if (not last(staticBoxes[1])) and (not last(staticBoxes[2])) and (not last(staticBoxes[3])) then
      gameIsOver = true
      gameResult = "win"
    end
  end

  ---------------
  -- Рендеринг --
  ---------------
  if gameIsOver and not gameOverGroup then
    createGameOverBackground()
    display.remove(livesGroup)
    createLivesGroup()
  end
  
  if not gameIsOver then
    display.remove(livesGroup)
    createLivesGroup()

    if activeBox then
      activeBox.view.y = activeBox.y
      activeBox.view.x = boxXPositions[activeBox.col]
    end
  end

end


function scene:show(event)
  if (event.phase == "did") then
    createMainGroup()
    createGameGroup()
    inputReader.start()
    Runtime:addEventListener("enterFrame", tick)
  end
end


function scene:hide(event) 
  if (event.phase == "did") then
    inputReader.stop()
    Runtime:removeEventListener("enterFrame", tick)
    composer.removeScene("scenes.game")
  end
end


scene:addEventListener("show")
scene:addEventListener("hide")

return scene