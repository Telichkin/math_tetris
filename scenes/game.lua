local composer = require("composer")
local widget = require("widget")
local tasks = require("lib.tasks")
local utils = require("lib.utils")
local state = require("lib.state")
local sound = require("lib.sound")
local inputReader = require("lib.inputReader")

-- Основная проблема -- это синхронизация игрового состояния с состоянием UI
-- и игровых объектов. Corona -- это retain mode SDK со всеми вытекающими.
-- Решить проблему синхронизации можно путем сохранения двух состояний:
-- предыдущего и текущего и внесения изменений в игровые объекты и UI на
-- основании анализа этих двух состояний


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
local boxWidth = fieldW / numberOfBoxesW - (2 * boxMarginX)
local boxHeight = fieldH / numberOfBoxesH - 5
local boxXPositions = {-(boxMarginX * 1.5 + boxWidth), 0, (boxMarginX * 1.5 + boxWidth)}
local startY = ((boxHeight - fieldH) / 2) - ((boxHeight + boxMarginY) * 1.5)

local heartH = (display.contentHeight - fieldH) * 0.5 * 0.6
local heartStartX = display.contentCenterX - (fieldW / 2) + (heartH / 2)
local heartStartY = display.contentCenterY - (display.contentHeight / 2) + ((display.contentHeight - fieldH) / 4)

local maxLives = 3
local maxPositionY = {display.contentHeight, display.contentHeight, display.contentHeight}
local lvlTasks, lvlNumbers = {}, {}

----------------------------------
-- Глобальное состояние рендера --
----------------------------------
local scene = composer.newScene()
local gameGroup
local mainGroup
local gameOverWindow
local livesGroup
local activeBoxR
local staticBoxesR = {{}, {}, {}}

-------------------------------
-- Глобальное состояние игры --
-------------------------------
local currS = {
  inited = false,
  isOver = false,
  result = "idle",
  lives = maxLives,
  -- boxes
  active = nil,
  static = {{}, {}, {}},  -- Каждый массив -- это колонка на игровом поле
}
local prevS = utils.deepCopy(currS)

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
  mainGroup:insert(gameGroup)
  local background = display.newRoundedRect(gameGroup, 0, 0, gameGroup.width, gameGroup.height, 0)
  background:setFillColor(1, 1, 1)
end


local function createOpacityBkg()
  local opacity = display.newRect(
    mainGroup, display.contentCenterX, display.contentCenterY, 
    display.contentWidth, display.contentHeight
  )
  opacity:setFillColor(utils.rgb(0, 0, 0, 0.5))
end


local function createGameOverWindow()
  gameOverWindow = display.newGroup()
  gameOverWindow.x = display.contentCenterX
  -- gameOverWindow.y = display.contentCenterY

  local W, H = mainGroup.width * 0.85, mainGroup.height * 0.7
  local background = display.newRect(gameOverWindow, 0, 0, W, H)
  background:setFillColor(utils.rgb(255, 255, 255, 1))
  background.strokeWidth = 4
  background:setStrokeColor(utils.rgb(149, 175, 237))

  local title = display.newText(
    gameOverWindow, 
    currS.result == "win" and "Уровень пройден!" or "Попробуй ещё раз",
    0,
    - (H / 2) + 40,
    mainFont, 27
  )
  title:setFillColor(utils.rgb(0, 0, 0))

  local persona = display.newImage(
    gameOverWindow,
    "assets/images/" .. (currS.result == "win" and "win" or "lose") .. ".jpg",
    0, -30
  )
  local pW, pH = persona.width, persona.height
  persona.height = H * 0.36
  persona.width = persona.height / pH * pW

  local toMenu = display.newText(gameOverWindow, "Меню", 0, persona.y + (persona.height / 2) + 35, mainFont, 27)
  toMenu:setFillColor(utils.rgb(0, 0, 0))

  toMenu:addEventListener("tap", gotoMenu)

  local btnGroup = display.newGroup()
  local btn = display.newRect(btnGroup, 0, 0, W * 0.6, 70)
  btn:setFillColor(utils.rgb(255, 255, 255))
  btn.strokeWidth = 3
  btn:setStrokeColor(utils.rgb(56, 102, 204))

  local btnText = display.newText({
    parent = btnGroup, 
    text = currS.result == "win" and "Следующий\nуровень" or "Играть\nснова", 
    x = 0, 
    y = 0, 
    font = mainFont, 
    fontSize = 26,
    align = "center",
  })
  btnText:setFillColor(utils.rgb(0, 0, 0))
  btnGroup.x = 0
  btnGroup.y = (H / 2) - 50
  gameOverWindow:insert(btnGroup)
  mainGroup:insert(gameOverWindow)

  btnGroup:addEventListener("tap", function ()
    if currS.result == "win" then
      state.lvl = utils.nextLvl(state.lvl)
    end
    composer.gotoScene("scenes.toGame")
  end)

  transition.to(gameOverWindow, {time = 1300, y = display.contentCenterY, transition = easing.outExpo})
end


local function createBox(b)
  box = display.newGroup()
  gameGroup:insert(box)
  -- у нас три разных типа изображений блоков
  local name = "block-" .. tostring(math.random(3)) .. ".png"
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
  for i = 1, currS.lives do
    local shape = display.newImageRect(livesGroup, "assets/images/heart.png", heartH, heartH)
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
  if not currS.inited then lastTickMs = event.time end

  local ms = event.time
  local deltaMs = ms - lastTickMs
  lastTickMs = ms

  --------------------
  -- Чтение инпута  --
  --------------------
  local lastEvent = inputReader.getLastEvent()
  
  ---------------------------------
  -- Сохраняем прошлое состояние --
  ---------------------------------
  prevS = utils.deepCopy(currS)

  --------------------------
  -- Обновление состояния --
  --------------------------
  if not currS.isOver then
    if not currS.inited then
      lvlTasks, lvlNumbers = tasks.generate(state.lvl.task, state.lvl.limit)
      local scheme = state.lvl.scheme

      for row = 1, #scheme do
        for col = 1, 3 do
          local type = scheme[row][col]
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
      currS.inited = true
    end

    if currS.active == nil then
      currS.active = {
        col = math.random(3),
        y = startY,
        task = tasks.createOne(lvlTasks, lvlNumbers, true, nil, last(currS.static[1]), last(currS.static[2]), last(currS.static[3])),
        speed = 1,
      }
    end

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

    currS.active.y = currS.active.y + (currS.active.speed * deltaMs * 20 / display.height)

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
      currS.isOver = true
      currS.result = "lose"
    end

    -- Победил, если поле осталось чистым
    if (not last(currS.static[1])) and (not last(currS.static[2])) and (not last(currS.static[3])) then
      currS.isOver = true
      currS.result = "win"
    end
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
  if prevS.inited == false and currS.inited == true then
    createMainGroup()
    createGameGroup()
    createLivesGroup()
    activeBoxR = createBox(currS.active)
    for i, col in pairs(currS.static) do
      for j, box in pairs(col) do
        staticBoxesR[i][j] = createBox(box)
      end
    end
  end

  -- Игра закончилась
  if prevS.isOver == false and currS.isOver == true then
    createOpacityBkg()
    createGameOverWindow()
  end
  
  -- Уменьшились жизни
  if prevS.lives > currS.lives then
    display.remove(livesGroup)
    createLivesGroup()
  end

  -- Активный блок появился
  if prevS.active == nil and currS.active ~= nil then
    activeBoxR = createBox(currS.active)
  end

  -- Активный блок исчез
  if prevS.active ~= nil and currS.active == nil then
    local activeBoxRToDelete = activeBoxR
    transition.to(activeBoxRToDelete, {
      alpha = 0,
      time = 200,
      onComplete = function ()
        display.remove(activeBoxRToDelete)
      end
    })

    -- В какой колонке был активный блок в момент исчезновения
    local col = prevS.active.col
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

  if not currS.isOver and currS.active then
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
    if prevS.active.y > (startY + 100) then
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
end


function scene:show(event)
  if (event.phase == "did") then
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