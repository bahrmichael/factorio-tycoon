-- This represents a Node (or tile, or vertex) on a grid map
-- Graph search algorithms usually create some temporary information
-- for each single node they process to figure out the path requested.
-- We need to keep these data inside this custom structure.

-- Creates a new node
local function createNode(x, y, dist)
    local newNode = {
      x = x,                -- the x coordinate of the node
      y = y,                -- the y-coordinate of the node
      distance = dist or 0  -- the distance (will be calculated by the search algorithm)
    }
    return newNode
  end
  
  return createNode