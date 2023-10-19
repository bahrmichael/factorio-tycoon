local Queue = {}

--- Create a new queue.
--- @return table Queue with first and last indices.
function Queue.new ()
    return {first = 0, last = -1}
end

--- Push an element to the left of the queue.
--- @param queue table The queue to push to.
--- @param value any The value to push.
function Queue.pushleft (queue, value)
    local first = queue.first - 1
    queue.first = first
    queue[first] = value
end

--- Push an element to the right of the queue.
--- @param queue table The queue to push to.
--- @param value any The value to push.
function Queue.pushright (queue, value)
    local last = queue.last + 1
    queue.last = last
    queue[last] = value
end

--- Pop an element from the left of the queue.
--- @param queue table The queue to pop from.
--- @return any Value
function Queue.popleft (queue)
    local first = queue.first
    -- queue is empty
    if first > queue.last then return nil end
    local value = queue[first]
    queue[first] = nil        -- to allow garbage collection
    queue.first = first + 1
    return value
end

--- Pop an element from the right of the queue.
--- @param queue table The queue to pop from.
--- @return any Value
function Queue.popright (queue)
    local last = queue.last
    -- queue is empty
    if queue.first > last then return nil end
    local value = queue[last]
    queue[last] = nil         -- to allow garbage collection
    queue.last = last - 1
    return value
end

--- Insert an element at a specific position in the queue.
--- @param queue table The queue to insert into.
--- @param value any The value to insert.
--- @param position number The position where the value should be inserted.
function Queue.insert(queue, value, position)
    local last = queue.last
    local first = queue.first

    if position < first then
        Queue.pushleft(queue, value)
        return
    elseif position > last + 1 then
        Queue.pushright(queue, value)
        return
    else
        -- Shift elements to the right to make space for the new value
        for i = last, position, -1 do
            if queue[i + 1] == nil then
                -- If the next element was nil, we can stop shifting values to the right here
                -- We're shifting a value into a free cell
                queue[i + 1] = queue[i]
                break
            else
                queue[i + 1] = queue[i]
            end
        end

        -- Insert the value at the specified position
        queue[position] = value
        queue.last = last + 1
    end
end

--- Create an iterator to iterate over all values in the queue.
--- Use it like this
--- local iterator = Queue.iterate(myQueue)
--- for value in iterator do
--- @param queue table The queue to iterate over.
--- @return function Iterator
function Queue.iterate(queue)
    local index = queue.first - 1
    local last = queue.last

    return function()
        index = index + 1
        if index <= last then
            return queue[index]
        end
    end
end

--- Get the number of non-empty elements in the queue.
--- @param queue table The queue to count non-empty elements in.
--- @param fast boolean | nil
--- @return number The number of non-empty elements in the queue.
function Queue.count(queue, fast)

    if queue == nil then
        return 0
    end

    local count = 0

    if fast then
        return queue.last - queue.first + 1
    end

    for i = queue.first, queue.last do
        if queue[i] ~= nil then
            count = count + 1
        end
    end

    return count
end

--- Remove duplicate values from the queue.
--- @param queue table The queue to remove duplicates from.
function Queue.removeDuplicates(queue, toKey)
    local uniqueValues = {}
    local newQueue = Queue.new()
    for i = queue.first, queue.last, 1 do
        if queue[i] ~= nil then
            local value = toKey(queue[i])
            if not uniqueValues[value] then
                Queue.pushright(newQueue, queue[i])
                uniqueValues[value] = true
            end
        end
    end
    return newQueue
end


return Queue