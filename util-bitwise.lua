-- could require("__stdlib__/utils/math"), though it has few off-by-one errors (as of 2024-03-02)

--local MIN_S32 = -2147483648
--local MAX_S32 =  2147483647
--local MIN_S16 = -32768
--local MAX_S16 =  32767
local MAX_U16 =  65535
local MASK15 = 0x00007fff
local MASK16 = 0x0000ffff
local MASK32 = 0xffffffff
local MSIG16 = MASK15 + 1
--local MSIG32 = 0x80000000

--
-- Factorio-Lua, OHNOES - bitwise operators, please!
--
local _and = bit32.band
local _or  = bit32.bor
local _ls  = bit32.lshift
local _rs  = bit32.rshift


-- module
local M = {}

--- this is similar to packing 2xInt8 like this:
--- FEDCBA9876543210 bit position
--- SxxxxxxxBbbbbbbb 16-bit signed
--- SbbbbbbbSbbbbbbb  8-bit signed x2
function M.pack2xInt16(x, y)
    --return ( ((y & MASK16) << 16) | (x & MASK16) ) & MASK32
    return _and(_or(
        _ls(_and(y, MASK16), 16),
            _and(x, MASK16)
    ), MASK32)
end

function M.unpack2xInt16(k)
    local x = _and(k, MASK16)  -- k & MASK16
    local y = _rs(k, 16)       -- k >> 16

    --log(string.format("k: 0x%08x xy: {0x%04x 0x%04x} xy_u16: {%d %d}", k, x, y, x, y))
    x = x + ((_and(x, MSIG16) ~= 0) and -(MAX_U16 + 1) or 0)  -- (x & MSIG16) ~= 0
    y = y + ((_and(y, MSIG16) ~= 0) and -(MAX_U16 + 1) or 0)  -- (y & MSIG16) ~= 0
    return { x, y }
end

--
-- tests
--
assert(M.pack2xInt16(    -2,     -3) == 0xfffdfffe)
assert(M.pack2xInt16( 65534,  65533) == 0xfffdfffe)
assert(M.pack2xInt16(-16657,  -8531) == 0xDeadBeef)
assert(M.pack2xInt16( 48879,  57005) == 0xDeadBeef)
assert(M.pack2xInt16( 32767,  32766) == 0x7ffe7fff)
assert(M.pack2xInt16(-98305, -98306) == 0x7ffe7fff)
assert(M.pack2xInt16(-32767, -32766) == 0x80028001)
local xy = {}  -- luacheck: ignore
xy = M.unpack2xInt16(0xfffdfffe); assert(xy[1] ==     -2 and xy[2] ==     -3)
xy = M.unpack2xInt16(0xDeadBeef); assert(xy[1] == -16657 and xy[2] ==  -8531)
xy = M.unpack2xInt16(0x7ffe7fff); assert(xy[1] ==  32767 and xy[2] ==  32766)
xy = M.unpack2xInt16(0x80028001); assert(xy[1] == -32767 and xy[2] == -32766)


return M
