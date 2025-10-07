Love.js for LÖVE v11.5
============
Basically trying to adapt [love.js](https://github.com/TannerRogalsky/love.js) to the latest and greatest versions of LÖVE and Emscripten.

## Demos
 * [Specification Test](https://davidobot.net/lovejs/lovejs_spec/); [(Compatibility Version)](https://davidobot.net/lovejs/lovejs_spec_c/) (threads, coroutines, shaders!)
 * [Another Kind of World](https://davidobot.net/lovejs/akow/); [(Compatibility Version)](https://davidobot.net/lovejs/akow_c/)
 * [groverburger's 3D engine (g3d)](https://davidobot.net/lovejs/3d/); [(Compatibility Version)](https://davidobot.net/lovejs/3d_c/) (shaders, click canvas to lock)
 * [Supported Graphical Features Test](https://davidobot.net/lovejs/features/); [(Compatibility Version)](https://davidobot.net/lovejs/features_c/)

## Quickstart
```
love.js game.love game -c
```
Build a game with the compatibility version.

## Installation
Install the package from `npm`; no need to download this repo:
```
npm i love.js
```

or _globally_:
```
npm -g i love.js
```

## Usage
```
npx love.js [options] <input> <output>
```

or
```
love.js [options] <input> <output>
```

or (on Windows cmd and Powershell, according to https://github.com/Davidobot/love.js/issues/48)
```
npx love.js.cmd [options] <input> <output>
```

`<input>` can either be a folder or a `.love` file.
`<output>` is a folder that will hold debug and release web pages.

You can also replace `love.js` in the above command with `index.js` (or ` node index.js` on Windows) directly if the numpy install is giving you problems.

## Options:
```
-h, --help            output usage information
-V, --version         output the version number
-t, --title <string>  specify game name
-m, --memory [bytes]  how much memory your game will require [16777216]
-c, --compatibility   specify flag to use compatibility version
```

### Test it
1. Run a web server (while `cd`-ed into the `<output>` folder):
  - eg: `python -m http.server 8000`
2. Open `localhost:8000` in the browser of your choice.

## Notes
1. Compatibility version (`-c`) should work with most browsers. The difference is that pthreads aren't used. This results in *dodgy audio*. 
2. The normal version works in the latest Chrome and should work with the latest Firefox version. 

The normal version can throw `Uncaught ReferenceError: SharedArrayBuffer is not defined`. Fix is discussed [here](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer#Security_requirements). TL;DR 
Enable the following HTML reponse headers on the website you're hosting your project on:
```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: require-corp
```
> If you want to publish your game on one of the game hosting platforms, like [itch.io](https://itch.io/) for example:
> - if they include these headers, use the standard version
> - if they don't, use the compatibility mode instead (`-c`)
> 
> On itch.io, they are disabled by default, but they provide experimental support for it. Read more about this [here](https://itch.io/t/2025776/experimental-sharedarraybuffer-support).

3. Memory is now dynamically resized even with pthreads thanks to [this](https://github.com/emscripten-core/emscripten/pull/8365). Still needs a large-enough initial memory until I figure out how to properly wait for the memory to be sized-up before initialising all the file-system stuff (pointers [here](https://emscripten.org/docs/getting_started/FAQ.html#how-can-i-tell-when-the-page-is-fully-loaded-and-it-is-safe-to-call-compiled-functions)).
4. Shaders work (check out 3D demo), but require stricter type-checking. _The OpenGL ES Shading Language is type safe. There are no implicit conversions between types_ ([source](https://www.khronos.org/registry/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.pdf)). So something like
```GLSL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    return texturecolor * color / 2;
}
```
**won't** work, but changing line 4 to the code below will make everything run just fine:
```GLSL
return texturecolor * color / 2.0;
```

5. If you use `love.mouse.setGrabbed` or `love.mouse.setRelative`, the user needs to click on the canvas to "lock" the mouse.

6. Use `love.filesystem.getInfo(file_name)` before trying to read a potentially non-existent file. 

7. If you use a depth buffer, add the following line: `t.window.depth = 16` to your `config.lua` file to make sure normals aren't inverted in Firefox.

8. If you'd like to run javascript from within your game, you might find [the following repo useful](https://github.com/MrcSnm/Love.js-Api-Player).

9. **Canvas Resizing (Partial Support)**: The canvas element now automatically resizes when the browser window changes size. The resize handling includes:
   - Monitoring window resize events
   - Detecting fullscreen changes
   - Periodically checking for CSS-based size changes
   - Updating the canvas element dimensions to match its display size

   The canvas is styled to be responsive by default:
   ```css
   #canvas {
     width: 100%;
     max-width: 100%;
     max-height: 100vh;
   }
   ```

   **Current Limitations**:
   - The canvas element resizes, but the game's internal rendering viewport does not automatically scale. This means the game content will not resize to fill the new canvas dimensions - it will render at the original size specified in `conf.lua`.
   - `love.window.setMode()` cannot change the canvas size from within game code.
   - The `love.resize()` callback may not be triggered on canvas size changes.

   **Why**: These limitations exist because SDL/Emscripten in the current LÖVE build doesn't properly handle dynamic canvas resizing without engine-level modifications.

   **Recommended Approach**: Set your desired canvas size in `conf.lua` with `t.window.width` and `t.window.height`. The canvas will be responsive to browser window size changes, but the game will render at your specified resolution. For a full resizing solution, engine-level changes would be required (see issue #88 and #59 on the upstream repository).

## Building
### MacOS / Linux
Clone the [megasource](https://github.com/Davidobot/megasource/tree/emscripten) and [love](https://github.com/Davidobot/love/tree/emscripten) and then run `build_lovejs.sh` (with minor changes for file paths).

That should just work™. Make sure you have CMake installed, clone [emsdk](https://github.com/emscripten-core/emsdk) and edit `build_lovejs.sh` to point to the right paths.

Set up emsdk with the following settings:

``` bash
./emsdk install 2.0.0
./emsdk activate 2.0.0
```

Note, using v:2.0.0 is important as newer versions have depreciated `getMemory`


### Windows
Clone the [megasource](https://github.com/Davidobot/megasource/tree/emscripten) and [love](https://github.com/Davidobot/love/tree/emscripten) and then run `build_lovejs.bat` (with minor changes for file paths) in PowerShell.

Make sure you have CMake and Make (e.g. through [chocolatey](https://chocolatey.org/packages/make)), and that you have the latest Visual Studio build bundles installed. Clone [emsdk](https://github.com/emscripten-core/emsdk) and edit `build_lovejs.bat` to point to the right paths.
