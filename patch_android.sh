#!/usr/bin/env bash
# Runs after "flutter create". Sets app name and application id.
set -e
MANIFEST=android/app/src/main/AndroidManifest.xml
sed -i 's/android:label="[^"]*"/android:label="NoteNest"/' "$MANIFEST"
for f in android/app/build.gradle android/app/build.gradle.kts; do
  if [ -f "$f" ]; then
    sed -i 's/com\.notenest\.notenest/com.notenest.app/g' "$f"
    # keep namespace matching the generated MainActivity package
    sed -i 's/namespace = "com\.notenest\.app"/namespace = "com.notenest.notenest"/; s/namespace "com\.notenest\.app"/namespace "com.notenest.notenest"/' "$f"
  fi
done
echo "Android patched."
