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

local boxMarginX = 4
local boxMarginY = 6
local boxRadius = 0
local boxWidth = fieldW / numberOfBoxesW - 2 * boxMarginX
local boxHeight = fieldH / numberOfBoxesH - 5
local boxXPositions = {-(boxMarginX * 1.5 + boxWidth), 0, (boxMarginX * 1.5 + boxWidth)}

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

  local W, H = mainGroup.width * 0.8, mainGroup.height * 0.5
  local background = display.newRect(gameOverGroup, 0, 0, W, H)
  background:setFillColor(utils.rgb(255, 255, 255, 1))
  background.strokeWidth = 4
  background:setStrokeColor(utils.rgb(149, 175, 237))

  local btnGroup = display.newGroup()
  local btn = display.newRect(btnGroup, 0, 0, W * 0.6, 50)
  btn:setFillColor(utils.rgb(255, 255, 255))
  btn.strokeWidth = 3
  btn:setStrokeColor(utils.rgb(56, 102, 204))

  local btnText = display.newText(btnGroup, "В меню", 0, 0, mainFont, 26)
  btnText:setFillColor(utils.rgb(0, 0, 0))
  btnGroup.x = 0
  btnGroup.y = 0
  gameOverGroup:insert(btnGroup)
  scene.view:insert(gameOverGroup)

  btnGroup:addEventListener("tap", gotoMenu)
end


local unusedPool = {}
local usedPool = {}
local function renderBox(b)
  local box, text = unpack(table.remove(unusedPool) or {nil, nil})

  if (not box) or (not text) then
    box = display.newGroup()
    gameGroup:insert(box)
    
    local shape = display.newRect(box, 0, 0, boxWidth, boxHeight)
    shape:setStrokeColor(utils.rgb(29, 41, 147, 1))
    shape.strokeWidth = 3

    text = display.newText(box, "", 0, 0, mainFont, 17)
    text:setFillColor(0, 0, 0)
  end

  box.y = b.y
  box.x = boxXPositions[b.col]

  if (b.task.type == "number") then
    text.text = tostring(b.task.n)
  else
    text.text = b.task.type:gsub("a", b.task.a):gsub("b", b.task.b)
  end

  table.insert(usedPool, {box, text})
end


local function freePool()
  for i, item in pairs(unusedPool) do
    display.remove(item[1])
    display.remove(item[2])
  end
  unusedPool = {}

  for i, item in pairs(usedPool) do
    item.x = display.contentWidth + 1000
    item.y = display.contentHeight + 1000
    table.insert(unusedPool, item)
  end
  usedPool = {}
end


local function createLivesGroup()
  livesGroup = display.newGroup()
  livesGroup.y = heartStartY
  livesGroup.x = heartStartX
  mainGroup:insert(livesGroup)
  for i = 1, maxLives do
    local shape = display.newCircle(livesGroup, ((i - 1) * (heartH + 5)), 0, heartH / 2)
    shape:setStrokeColor(utils.rgb(29, 41, 147, 1))
    shape.strokeWidth = 2
    if i <= lives then
      -- Оставшиеся жизни
      shape:setFillColor(utils.rgb(239, 97, 97))
    else
      -- Потраченные жизни
      shape:setFillColor(utils.rgb(255, 255, 255))
    end
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
      lvlTasks, lvlNumbers = tasks.generate(state.task, state.limit)
      -- TODO: Схема расположения статических боксов должно читаться из глобального стейта (lib.state).
      -- Схема читается наоборот, то есть снизу вверх.
      local scheme = {
        {"task", "task", "task"},
        {"task", "task", "task"},
        {"task", "task", " "},
        {"task", "task", " "},
      }

      for row = 1, #scheme do
        for col = 1, 3 do
          local type = scheme[row][col]
          if type ~= " " then
            staticBoxes[col][row] = {
              col = col, 
              y = (fieldH / 2) - ((row - 1) * (boxHeight + boxMarginY)) - (boxHeight / 2 + boxMarginY),
              task = tasks.createOne(lvlTasks, lvlNumbers, false, type, last(staticBoxes[col])),
              speed = 0,
              health = 100,  -- Уменьшается, если боксы столкнулись
              collide = false,
            }
          end
        end
      end
      gameInited = true
    end

    if activeBox == nil then
      activeBox = {
        col = math.random(3),
        y = ((boxHeight - fieldH) / 2) - ((boxHeight + boxMarginY) * 1.5),
        task = tasks.createOne(lvlTasks, lvlNumbers, true, nil, last(staticBoxes[1]), last(staticBoxes[2]), last(staticBoxes[3])),
        speed = 1,
        health = 100,
        collide = flase,
      }
    end

    local prevCol = activeBox.col
    if lastEvent == "Swipe Left" then
      activeBox.col = (activeBox.col - 1 < 1) and 1 or activeBox.col - 1
    elseif lastEvent == "Swipe Right" then
      activeBox.col = (activeBox.col + 1 > 3) and 3 or activeBox.col + 1
    elseif lastEvent == "Swipe Down" then
      activeBox.speed = 15
    end

    activeBox.y = activeBox.y + (activeBox.speed * deltaMs / 30)

    local nearBox = last(staticBoxes[activeBox.col])
    local maxY = (nearBox and nearBox.y - (boxHeight + boxMarginY)) or ((fieldH / 2) - (boxHeight / 2 + boxMarginY))
    if activeBox.y >= maxY then
      -- Столкновение с другим боксом по горизонтали
      if prevCol ~= activeBox.col then
        activeBox.col = prevCol
      -- Столкновение с другим боксом по вертикали
      else
        local wrongBoxes = (
          not nearBox or
          (nearBox.task.type ~= "number" and nearBox.task["?"] ~= activeBox.task.n) or
          (nearBox.task.type == "number" and nearBox.task.n ~= activeBox.task["?"])
        )
        if wrongBoxes then lives = lives - 1 end
        activeBox = nil

        if nearBox then
          table.remove(staticBoxes[nearBox.col], #staticBoxes[nearBox.col])
        end
      end
    end
    
    -- Проиграл
    if lives == 0 then
      gameIsOver = true
    end

    -- Победил
    if (not last(staticBoxes[1])) and (not last(staticBoxes[2])) and (not last(staticBoxes[3])) then
      gameIsOver = true
    end
  end

  ---------------
  -- Рендеринг --
  ---------------
  if not mainGroup then
    createMainGroup()
  end

  if not gameGroup then
    createGameGroup()
  end

  if gameIsOver and not gameOverGroup then
    createGameOverBackground()
    display.remove(livesGroup)
    createLivesGroup()
  end
  
  if not gameIsOver then
    display.remove(livesGroup)
    createLivesGroup()

    if activeBox then
      renderBox(activeBox)
    end

    for col = 1, #staticBoxes do
      for row = 1, #staticBoxes[col] do
        renderBox(staticBoxes[col][row])
      end
    end
    freePool()
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