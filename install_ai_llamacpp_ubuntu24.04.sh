#!/usr/bin/env bash

set -e

echo "🔧 Installing llama.cpp on Ubuntu 24.04..."

# 1. Update system

echo "📦 Updating package list..."
sudo apt update

# 2. Install required dependencies

echo "📥 Installing build tools and dependencies..."
sudo apt install -y build-essential git cmake curl

# 3. Clone llama.cpp

INSTALL_DIR="$HOME/llama.cpp"

if [ -d "$INSTALL_DIR" ]; then
echo "📁 llama.cpp already exists at $INSTALL_DIR"
else
echo "📥 Cloning llama.cpp..."
git clone https://github.com/ggerganov/llama.cpp "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# 4. Build (CPU version)

echo "⚙️ Building (CPU version)..."
make clean || true
make -j$(nproc)

# 5. Create models directory

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
echo "💡 Tip: For better performance, use quantized models like Q4_K_M."
echo "💡 Optional: For NVIDIA GPUs, rebuild with CUDA support."
