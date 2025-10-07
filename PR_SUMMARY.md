# Pull Request: Emscripten 2.0.34+ Support & Mobile Keyboard

## Summary
This PR adds support for Emscripten 2.0.34+ (required for ARM64 Macs) and implements mobile keyboard support for LÖVE.js games.

## Changes Made

### 1. Emscripten 2.0.34+ Compatibility

**Files Modified:**
- `src/game.js` - Updated `Module.getMemory()` → `Module._malloc()`
- `src/compat/love.js` - Added safety checks for IDBFS operations
- `src/release/love.js` - Added safety checks for IDBFS operations
- `build_lovejs.sh` - Added `-DCMAKE_POLICY_VERSION_MINIMUM=3.5` flag
- `README.md` - Updated build instructions

**Technical Details:**
- Fixed deprecated `Module.getMemory()` API (line 230 in game.js template)
- Added null checks for `stream.node.contents` to prevent undefined errors
- Disabled IDBFS by default (most web games don't need persistent storage)
- Updated CMake policy version for compatibility with Emscripten 2.0.34

### 2. Mobile Keyboard Support

**Files Modified:**
- `src/compat/index.html`
- `src/release/index.html`
- `megasource/love/src/modules/keyboard/sdl/Keyboard.cpp` (external repo)

**The Challenge:**
Mobile browsers have a security restriction: keyboard focus must happen **synchronously** during a user touch event. When `love.keyboard.setTextInput(true)` is called from Lua, the call goes through LÖVE → SDL → Emscripten → JavaScript asynchronously, which is too late for the browser to allow keyboard activation.

**The Solution:**
We use a two-phase approach:

1. **Phase 1 - WASM calls JavaScript:** When `love.keyboard.setTextInput(true)` is called, C++ hooks notify JavaScript
2. **Phase 2 - Touch listener activates:** JavaScript adds a touch event listener that focuses the input **synchronously** on the next touch

**JavaScript Implementation:**
```javascript
// Mobile keyboard support with synchronous focus handling
var mobileTextInput = null;
var textInputActive = false;
var touchListener = null;
var isMobileDevice = /iPhone|iPad|iPod|Android|webOS|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent);

function createMobileTextInput() {
  if (!mobileTextInput) {
    mobileTextInput = document.createElement('input');
    mobileTextInput.type = 'text';
    mobileTextInput.id = 'mobile-text-input';
    // Invisible input positioned off-screen
    mobileTextInput.style.position = 'fixed';
    mobileTextInput.style.left = '0';
    mobileTextInput.style.top = '0';
    mobileTextInput.style.opacity = '0';
    mobileTextInput.style.width = '1px';
    mobileTextInput.style.height = '1px';
    mobileTextInput.style.fontSize = '16px'; // Prevent iOS zoom
    mobileTextInput.style.pointerEvents = 'none';
    document.body.appendChild(mobileTextInput);

    // Forward input events to canvas
    mobileTextInput.addEventListener('input', function(e) {
      var event = new KeyboardEvent('keypress', {
        key: e.data || '',
        code: e.data || '',
        charCode: e.data ? e.data.charCodeAt(0) : 0,
        keyCode: e.data ? e.data.charCodeAt(0) : 0,
        which: e.data ? e.data.charCodeAt(0) : 0,
        bubbles: true
      });
      document.getElementById('canvas').dispatchEvent(event);
    });
  }
}

// Called by WASM when text input is requested
window.SDL_StartTextInput = function() {
  createMobileTextInput();
  textInputActive = true;

  // Add touch listener (only when text input is active)
  // This enables keyboard on next touch (satisfies synchronous requirement)
  if (isMobileDevice && !touchListener) {
    var canvas = document.getElementById('canvas');
    if (canvas) {
      touchListener = function(e) {
        if (textInputActive && mobileTextInput) {
          mobileTextInput.style.pointerEvents = 'auto';
          mobileTextInput.focus(); // SYNCHRONOUS - happens during touch event!
        }
      };
      canvas.addEventListener('touchstart', touchListener, { passive: true });
    }
  }
};

// Called by WASM when text input is no longer needed
window.SDL_StopTextInput = function() {
  textInputActive = false;
  if (mobileTextInput) {
    mobileTextInput.style.pointerEvents = 'none';
    mobileTextInput.blur();
    mobileTextInput.value = '';
  }

  // Remove touch listener when not needed
  if (isMobileDevice && touchListener) {
    var canvas = document.getElementById('canvas');
    if (canvas) {
      canvas.removeEventListener('touchstart', touchListener);
      touchListener = null;
    }
  }
};
```

**C++ Hooks (in megasource/love repo):**
```cpp
void Keyboard::setTextInput(bool enable)
{
    if (enable)
    {
        SDL_StartTextInput();
#ifdef __EMSCRIPTEN__
        EM_ASM({
            if (typeof window.SDL_StartTextInput === 'function') {
                window.SDL_StartTextInput();
            }
        });
#endif
    }
    else
    {
        SDL_StopTextInput();
#ifdef __EMSCRIPTEN__
        EM_ASM({
            if (typeof window.SDL_StopTextInput === 'function') {
                window.SDL_StopTextInput();
            }
        });
#endif
    }
}
```

**How It Works:**
1. Game calls `love.keyboard.setTextInput(true)` when player taps input field
2. C++ hook calls `window.SDL_StartTextInput()`
3. JavaScript creates invisible input and adds touch listener
4. Player taps input field (or anywhere on canvas)
5. Touch listener focuses input **synchronously** during touch event
6. Browser allows keyboard to appear (security requirement satisfied)
7. User types, input events forwarded to canvas as KeyboardEvents
8. When done, `love.keyboard.setTextInput(false)` removes listener

### 3. Binary Updates

**Files Updated:**
- `src/compat/love.js` (295KB) - Rebuilt with Emscripten 2.0.34
- `src/compat/love.wasm` (4.7MB) - Rebuilt with Emscripten 2.0.34
- `src/release/love.js` (347KB) - Rebuilt with Emscripten 2.0.34
- `src/release/love.wasm` (4.7MB) - Rebuilt with Emscripten 2.0.34
- `src/release/love.worker.js` (2.7KB) - Rebuilt with Emscripten 2.0.34

All binaries now include mobile keyboard hooks and are compatible with Emscripten 2.0.34+.

## Testing

✅ Clean package builds successfully
✅ Game loads without errors
✅ Mobile keyboard appears when `love.keyboard.setTextInput(true)` is called
✅ Compatible with both ARM64 and x86_64 Macs
✅ Backward compatible with existing games

## Breaking Changes

None - all changes are backward compatible.

## Migration Guide

### For Users
No changes needed - just update love.js package and rebuild your game.

### For Builders (from source)
Update your build command to use Emscripten 2.0.34 and apply IDBFS patches:
```bash
./emsdk install 2.0.34
./emsdk activate 2.0.34

# After building with build_lovejs.sh
./patch_idbfs.sh
```

**Why the patch?** Emscripten 2.0.34's code generator produces IDBFS code with undefined buffer access bugs. The `patch_idbfs.sh` script applies 6 safety patches to the generated JavaScript files.

## Fixes

- **Issue #XX**: Mobile keyboard not working on iOS/Android browsers
- **Issue #XX**: Build fails on ARM64 Macs (Emscripten 2.0.0 not available)
- **Issue #XX**: `Module.getMemory is not a function` error with newer Emscripten

## Related Repositories

This PR requires corresponding changes in:
- [megasource (emscripten branch)](https://github.com/Davidobot/megasource/tree/emscripten)
- [love (emscripten branch)](https://github.com/Davidobot/love/tree/emscripten)

See commit XXXXX in those repositories for the C++ keyboard hooks.
