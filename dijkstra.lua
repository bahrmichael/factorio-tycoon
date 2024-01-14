-- Dijkstra graph search algorithm implementation
-- See [1] for description
-- [1] : http://en.wikipedia.org/wiki/Dijkstra%27s_algorithm

-- Processes the graph for shortest paths using Dijkstra search algorithm
-- source  is the starting node from which the search will spread.
-- Note: This implementation can be optimized by replacing the list of node
-- with a more appropriate data structure, such as a min-heap (binary heap)
local function dijkstra(grid, source)
    local listOfNodes = grid.getAllNodes() -- Get the list of all nodes
    -- We set all nodes distance to infinity, and clear their previous property, if defined.
    for i, node in ipairs(listOfNodes) do
      node.distance = math.huge
      node.previous = nil
    end
    
    -- We set the source node distance to 0, and sort the list of node in increasing 
    -- distance order, so that the source node bubbles at the top of this list.
    source.distance = 0
    table.sort(listOfNodes, function(nodeA, nodeB) return nodeA.distance < nodeB.distance end)  
    
    -- While there are still some nodes to examine in our list
    while (#listOfNodes > 0) do
      -- We pop and remove the node at the top of this list.
      -- It should be the node with the lowest distance.
      local currentNode = listOfNodes[1]
      table.remove(listOfNodes, 1)
      
      -- In case we got an unprocessed node, we stop everything (this should not occur, normally).
      if currentNode.distance == math.huge then break end
      
      -- We get the neighbors of the current node
      local neighbors = grid.getNeighbors(currentNode)
      for _, neighborNode in ipairs(neighbors) do
        -- We calculate the cost of move from the current node to its neighbor
        local costOfMoveToNeighborNode = grid.getMapValue(neighborNode.x, neighborNode.y)
        local distanceToNeighborNode = grid.distance(currentNode, neighborNode, costOfMoveToNeighborNode)
        local alt = currentNode.distance + distanceToNeighborNode
        -- We relax the edge (currentNode->neighbor) in case there is a better alternative
        if alt < neighborNode.distance then
          neighborNode.distance = alt
          neighborNode.previous = currentNode
          -- If so, as the neighbor node was updated, we sort the list of nodes in increasing distance order)
          table.sort(listOfNodes, function(nodeA, nodeB) return nodeA.distance < nodeB.distance end)
        end
      end
    end
    
  end
  
  return dijkstra