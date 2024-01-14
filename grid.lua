-- A grid map handler
-- This handler is devised for 2D weighted grids. Nodes are indexed
-- with a pair of (x, y) coordinates.
-- It features cardinal (4-directions) and octal (8-directions) moves.

-- (see node.lua)
local createNode  = require ('node')

-- Direction vectors will be used to retrieve the neighbors of a given node
local cardinalVectors = {{x =  0, y = -1}, {x = -1, y =  0}, {x =  1, y =  0}, {x =  0, y =  1}}
local diagonalVectors = {{x = -1, y = -1}, {x =  1, y = -1}, {x = -1, y =  1}, {x =  1, y =  1}}

-- Gridmap handler template
-- The passable field should be provided. It acts as a validation function 
-- that checks if a value on the weighted map should be considered as passable or not.
local handler = {
  map = nil,        -- This will serves as a reference to the game map (weighted map)   
  nodes =  {},      -- 2D array of nodes (see node.lua)
  diagonal = false, -- Specifies if diagonal moves are allowed (not allowed by default)
  passable = nil,   -- to be implemented.
}

-- Inits a gridmap handler. We pass it a weighted map,
-- and it processes this map to create the number of nodes needed.
function handler.create(map)
  handler.map = map
  handler.nodes = {}
  for y, row in ipairs(map) do
    handler.nodes[y] = {}
    for x in ipairs(row) do
      handler.nodes[y][x] = createNode(x, y)
    end
  end
end

-- Returns an array list of all the nodes
function handler.getAllNodes()
  local listOfNodes = {}
  for y, row in ipairs(handler.nodes) do
    for x, node in ipairs(row) do
      table.insert(listOfNodes, node)
    end
  end
  return listOfNodes
end

-- Returns the map value at coordinate pair (x,y)
-- Returns nil in case (x,y) is not a valid pair
function handler.getMapValue(x, y)
  return handler.map[y] and handler.map[y][x]
end

-- Returns the node at coordinate pair (x,y)
-- Returns nil in case (x,y) is not a valid pair
function handler.getNode(x, y)
  return handler.nodes[y] and handler.nodes[y][x]
end

-- Checks if (x,y) is a valid pair of coordinates and if
-- mapValue(x,y) is passable.
function handler.isPassableNode(x, y)
  local mapValue = handler.getMapValue(x, y)
  if mapValue then return handler.passable(mapValue) end
  return false
end

-- Returns Manhattan distance between nodes a and node b
-- This should be the heuristic of choice for cardinal grids.
function handler.calculateManhattanDistance(a, b, costOfMove)
  local dx, dy = a.x - b.x, a.y - b.y
  return (costOfMove or 1) * (math.abs(dx) + math.abs(dy))
end

-- Returns diagonal distance between node a and node b
-- This should be the heuristic of choice for octal grids.
function handler.calculateDiagonalDistance(a, b, costOfMove)
  local dx, dy = math.abs(a.x - b.x), math.abs(a.y - b.y)
  return (costOfMove or 1) * math.max(dx, dy)
end

-- Returns an array-list of neighbors of node n.
function handler.getNeighbors(n)
  local neighbors = {}
  -- Gets the list of cardinal passable neighbors
  for _, axis in ipairs(cardinalVectors) do
    local x, y = n.x + axis.x, n.y + axis.y
    if handler.isPassableNode(x, y) then
      table.insert(neighbors, handler.getNode(x, y))
    end
  end
  -- In case diagonal movement is allowed
  if handler.diagonal then
    -- Adds also adjacent passable neighbors
    for _, axis in ipairs(diagonalVectors) do
      local x, y = n.x + axis.x, n.y + axis.y
      if handler.isPassableNode(x, y) then
        table.insert(neighbors, handler.getNode(x,y))
      end
    end
  end
  return neighbors
end

-- Returns a path from start node to goal node which does not exceed
-- a maximumCost. This function reads the graph actual state after it
-- has been processed by Dijkstra. As such, it goes from the start nodes
-- and walks towards the goal node while counting the cost of the total
-- move. In case the actualCost of move exceeds to maximumCost allowed,
-- it stops and returns an incomplete path. In case one wants the full path,
-- maximumCost should be omitted, thus will fallback to infinity.
 function handler.findPath(start, goal, maximumCost)
  local path = {{x = start.x, y = start.y}} -- add the start node to the path
  local previous, oldPrevious = start
  
  local actualCost = 0
  maximumCost = maximumCost or math.huge
  
  -- Let us backtrack the path by moving downhill the distance map.
  repeat  
  oldPrevious = previous
  previous = previous.previous
  -- we calculate the cost of move of a single step
  local costOfMove = (oldPrevious.distance - previous.distance)
  -- in case we cannot afford it, we stop and return an incomplete path
  if actualCost + costOfMove > maximumCost then
    break
  else
    -- otherwise, we increase the actual cost, and register the step in the path
    actualCost = actualCost + costOfMove
    table.insert(path,{x = previous.x, y = previous.y})
  end
  until previous == goal  -- stop backtracking when we have reached the goal.
    
  -- we return the path, plus the total cost.
  return path, actualCost
end

return handler