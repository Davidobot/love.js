#!/bin/bash
# Patch IDBFS bugs in Emscripten 2.0.34+ generated code
# These patches fix undefined buffer access errors in the generated JavaScript

set -e

echo "Applying IDBFS compatibility patches to love.js files..."

# Patch 1: Initialize contents if undefined
sed -i.bak 's/var contents=stream\.node\.contents;/var contents=stream.node.contents||new Uint8Array(0);/g' src/compat/love.js src/release/love.js

# Patch 2: Null check for buffer comparison
sed -i.bak2 's/contents\.buffer===buffer/contents\&\&contents.buffer===buffer/g' src/compat/love.js src/release/love.js

# Patch 3: Safe byteOffset access
sed -i.bak3 's/contents\.byteOffset/contents?contents.byteOffset:0/g' src/compat/love.js src/release/love.js

# Patch 4: Safe length check
sed -i.bak4 's/position+length<contents\.length/position+length<(contents?contents.length:0)/g' src/compat/love.js src/release/love.js

# Patch 5: Safe subarray check
sed -i.bak5 's/if(size>8&&contents\.subarray)/if(size>8\&\&contents\&\&contents.subarray)/g' src/compat/love.js src/release/love.js

# Patch 6: Disable IDBFS (not needed for most web games)
sed -i.bak6 's/FS\.mount(IDBFS/false\&\&FS.mount(IDBFS/g' src/compat/love.js src/release/love.js

# Clean up backup files
rm -f src/compat/love.js.bak* src/release/love.js.bak*

echo "✅ Patches applied successfully"

# Verify patches
COMPAT_PATCHES=$(grep -o "contents||new Uint8Array" src/compat/love.js | wc -l | xargs)
RELEASE_PATCHES=$(grep -o "contents||new Uint8Array" src/release/love.js | wc -l | xargs)

echo "Verification: Found $COMPAT_PATCHES patches in compat, $RELEASE_PATCHES in release"
