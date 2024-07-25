
local function orientation(p, q, r)
    local val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    if val == 0 then return 0 end
    return val > 0 and 1 or 2
end

local function grahamScan(points)
    if #points < 3 then return points end

    -- Find the bottommost point (and leftmost if there are multiple)
    local bottom = 1
    for i = 2, #points do
        if points[i].y < points[bottom].y or (points[i].y == points[bottom].y and points[i].x < points[bottom].x) then
            bottom = i
        end
    end

    -- Swap the bottommost point with the first point
    points[1], points[bottom] = points[bottom], points[1]

    -- Sort points based on polar angle with respect to the bottommost point
    local p0 = points[1]
    table.sort(points, function(a, b)
        local o = orientation(p0, a, b)
        if o == 0 then
            return (a.x - p0.x)^2 + (a.y - p0.y)^2 < (b.x - p0.x)^2 + (b.y - p0.y)^2
        end
        return o == 2
    end)

    -- Build the convex hull
    local stack = {points[1], points[2], points[3]}
    for i = 4, #points do
        while #stack > 1 and orientation(stack[#stack-1], stack[#stack], points[i]) ~= 2 do
            table.remove(stack)
        end
        table.insert(stack, points[i])
    end

    return stack
end


return {
    approximate_circle = grahamScan
}
