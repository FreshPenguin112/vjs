#!/data/data/com.termux/files/usr/bin/bash
set -e

# =========================
# CONFIG
# =========================
NDK_VERSION="r26d"
NDK_ZIP="android-ndk-${NDK_VERSION}-linux.zip"
NDK_URL="https://dl.google.com/android/repository/${NDK_ZIP}"

NDK_DIR="$HOME/android-ndk-${NDK_VERSION}"
BUILD_DIR="build-termux"
OUT_DIR="dist"

ABI="arm64-v8a"
API="24"

echo "===================================="
echo " QuickJS Termux Build"
echo "===================================="

# =========================
# 1. Install deps
# =========================
echo "[1/6] Installing dependencies..."
pkg update -y
pkg install -y wget unzip cmake clang make ninja

# =========================
# 2. Download NDK if missing
# =========================
echo "[2/6] Checking Android NDK..."

if [ ! -d "$NDK_DIR" ]; then
  echo "NDK not found. Downloading..."
  wget -O "$NDK_ZIP" "$NDK_URL"
  unzip "$NDK_ZIP" -d "$HOME"
  rm -f "$NDK_ZIP"
else
  echo "NDK already exists: $NDK_DIR"
fi

# =========================
# 3. Clean build
# =========================
echo "[3/6] Cleaning build..."
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$BUILD_DIR" "$OUT_DIR"

# =========================
# 4. Configure CMake
# =========================
echo "[4/6] Configuring CMake..."

cmake -S . -B "$BUILD_DIR" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=Android \
  -DANDROID_ABI="$ABI" \
  -DCMAKE_C_COMPILER=$(which clang) \
  -DANDROID_PLATFORM="$API" \
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
  -DCMAKE_MAKE_PROGRAM="$(which ninja 2>/dev/null || which make)"
# =========================
# 5. Build
# =========================
echo "[5/6] Building..."
cmake --build "$BUILD_DIR" --config Release

# =========================
# 6. Package
# =========================
echo "[6/6] Packaging..."

if [ ! -f "$BUILD_DIR/libqjs.a" ]; then
  echo "ERROR: build failed - libqjs.a not found"
  echo "Build directory contents:"
  ls -R "$BUILD_DIR"
  exit 1
fi

cp "$BUILD_DIR/libqjs.a" "$OUT_DIR/libqjs_termux_arm64.a"

echo "===================================="
echo " BUILD SUCCESS"
echo " Output: $OUT_DIR/libqjs_termux_arm64.a"
echo "===================================="

# =========================
# VERIFY
# =========================
echo "Symbol check:"
command -v nm >/dev/null 2>&1 && nm -g "$OUT_DIR/libqjs_termux_arm64.a" | head || true
