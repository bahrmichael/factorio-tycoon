# Remote Interfaces

This file describes the remote interfaces that Tycoon exposes. They are not intended for your regular gameplay, and your experience may suffer.

## spawn_city

**Warning: The mod will break if you spawn a city with a custom city name and you have public transportation researched. As long as you don't research public transportation, you should be able to use custom city names.**

You can [call this interface](https://lua-api.factorio.com/latest/classes/LuaRemote.html#call) with the following parameters:

```
interface = "tycoon"
function = "spawn_city"
... = position, surface_index, optional city name
```

Position is a coordinate on Factorio's tile grid, which contains an x and a y field. This function does not support Factorio's shorthand version.

Surface_index is the ID of the surface you want to place the city on. Use 1 if you want to place a city on the default surface (Nauvis).

You can specify or omit the optional city name. If you omit it, Tycoon will take one of its built-in city names which support public transporation.

Example call in game:

```
/c remote.call("tycoon", "spawn_city", {x = 10, y = 10}, 1, "My City Name")
```