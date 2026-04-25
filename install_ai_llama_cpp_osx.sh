#!/usr/bin/env bash

set -e

echo "🔧 Installing llama.cpp on macOS..."

# 1. Install Xcode Command Line Tools if not present

if ! xcode-select -p &>/dev/null; then
echo "📦 Installing Xcode Command Line Tools..."
xcode-select --install
echo "⚠️ Please re-run this script after installation completes."
exit 1
fi

# 2. Check for Homebrew (optional but useful)

if ! command -v brew &>/dev/null; then
echo "🍺 Homebrew not found. Installing..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
echo "✅ Homebrew already installed"
fi

# 3. Install git if missing

if ! command -v git &>/dev/null; then
echo "📥 Installing git..."
brew install git
fi

# 4. Clone llama.cpp

INSTALL_DIR="$HOME/llama.cpp"

if [ -d "$INSTALL_DIR" ]; then
echo "📁 llama.cpp already exists at $INSTALL_DIR"
else
echo "📥 Cloning llama.cpp..."
git clone https://github.com/ggerganov/llama.cpp "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 5. Build with Metal support (Apple Silicon optimization)

echo "⚙️ Building with Metal support..."
make clean || true
make LLAMA_METAL=1

# 6. Create models directory

mkdir -p models

echo ""
echo "✅ Installation complete!"
echo ""
echo "👉 Next steps:"
echo "1. Download a GGUF model (e.g. from Hugging Face)"
echo "2. Place it in: $INSTALL_DIR/models/"
echo "3. Run:"
echo "   ./main -m models/your-model.gguf -p "Hello!""
echo ""
echo "💡 Tip: Use smaller quantized models (Q4_K_M) for best performance."
