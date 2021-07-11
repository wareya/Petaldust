# Godot Auto Tileset

This is a Godot gdscript plugin which can automatically create tilesets based off of a specially formatted json file. If you've ever had to try and use autotiling with the built-in editor before you should know how much of a pain it is to do more than a single tile. After getting annoyed with it enough times, I created this plugin to automatically generate collision using a few different customizable algorithms that can be automatically applied to a texture, along with the ability to specify multiple textures into the same tileset at the same time.

## Usage

First step is to clone/download this plugin into your `/addons/` folder in your godot project. If the addons folder doesn't exist then you'll have to create it. If it is zipped, you will need to unzip it. The name of the unzipped folder doesn't matter. The end result should have a cfg file at `/addons/auto_tileset/plugin.cfg`.

There is an example folder in the repo that has an `example.tiles.example` file that specifies multiple different images inside of it. Open it up in your json editor of choice to see the general format of how it is laid out. Any json file that has an extension of `.json` or `.tiles` will be picked up by the import editor. You can copy this file and modify it as needed or create your own.

The format at the moment is basically just a Dictionary (`{}`) that has a single key (`"tiles":`) which is an Array (`[]`) of Dictionaries that represent each individual Tile. Each tile has a few keys that it is required to have, and a ton of optional keys. The optional keys can have a fallback defined in the import process so you don't need to keep repeating the same information over and over if all of your assets are in the same format.

**Required**:
* `name`: This is the display name that is used when you're actually using the tile in a TileMap.
* `texture`: This should be a path to a texture image or resource. The path can be relative or absolute (prefixed with `res://` or `user://` etc).

**Optional**:
* `tile_size`: How big each individual tile in texture is. `16`, `32`, `64`, etc.
* `type`: Determines what strategy will be used to import the tile
    * `"autotile"`: This tile should be treated as an autotile
    * `"single"`: Use this tile as-is.
    * `"minitiles"`: Convert a `1x5` tileset into a full `3x3minimal` autotile tileset.
* `bitmask`: What bitmask type does this autotile use?
    * `"2x2"`: Not currently supported
    * `"3x3minimal"`: Should be a texture that is 12 tiles wide, 4 tiles high, in the standard format. Look at the images in the examples directory.
    * `"3x3"`: Not currently supported
* `collision`:  This should be a string that is one of the following values:
    * `"none"`: Does not generate any collision. Can also be `""` or `false` if you prefer.
    * `"rectangle"`: Generates a full square for every tile. A very fast and dumb algorithm.
    * `"scanline"`: A pixel perfect algorithm that creates horizontal rectangles, then merges those rectangles vertically if possible. Generally won't create too many collision shapes.
    * `"convex"`: Godot has a built-in convex point cloud algorithm. It kind of approximates the shape but isn't particularly great at handling the information that i'm sending to it.

## Implemented Features

* Specify any number of textures to be added to the resulting TileSet resource
* Automatically generates a proper 3x3minimal bitmask based on the most common 3x3minimal layout.
* The paths to texture resources can be relative or absolute. It should be possible to point to any common texture Resource that godot supports including animated textures/etc but I haven't tested it yet.
* Allows defining the threshold for what is considered a "transparent" pixel for use in the algorithms (currently hardcoded to <0.5 alpha, will eventually move to an option)
* Multiple collision generation strategies:
    * FullRectangle: Just generates a full square collision shape for each tile, except for fully empty tiles.
    * Scanline: Traverses the tile pixel by pixel in a scanline, creating collision shapes for each row, then merges vertically to create larger rectangles if it can. Very unoptimized "pixel perfect" collision generation.
    * BuiltinConvexApproximation: Godot has a built-in convex point cloud approximation that kind of works. I'm probably using it improperly so the results aren't that great.

## Features still under construction

These are features that are planned but I haven't gotten around to adding yet.

* Does not currently have support for 2x2 bitmask autotile tilesets
* Does not support non-square tilesets at the moment. Should be easy to add I just haven't had a use for it yet.
* Does not currently support adding single individual tiles to a tileset
* It would be nice to automatically expand a "minitiles" format image into a full 3x3minimal autotile as an optional feature that can be enabled.
* It would be nice to generate a concave pixel-perfect collision shape for each tile. Might be able to modify my scanline generator to get part of the way there. If someone else knows a good algorithm to implement the concave generation that would be helpful.