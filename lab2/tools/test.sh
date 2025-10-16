#!/bin/bash

echo "=============================================="
echo "Running Buddy System Test Functions"
echo "=============================================="

cd ~/桌面/labcodes/lab2

echo "Step 1: Compiling with test flags..."
make clean
make "DEFS=-DBUDDY_SYSTEM_TEST"

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi
echo "✅ Compilation successful"

echo "Step 2: Running QEMU (this will take 10-15 seconds)..."
echo "----------------------------------------"

# 创建临时脚本来运行 QEMU
cat > run_qemu.sh << 'EOF'
#!/bin/bash
cd ~/桌面/labcodes/lab2
exec make qemu
EOF

chmod +x run_qemu.sh

# 在后台运行 QEMU
./run_qemu.sh &
QEMU_PID=$!

echo "QEMU started with PID: $QEMU_PID"
echo "Waiting for tests to complete..."

# 等待足够长时间让测试运行
sleep 12

# 检查 QEMU 是否还在运行
if kill -0 $QEMU_PID 2>/dev/null; then
    echo "Stopping QEMU..."
    kill $QEMU_PID
    sleep 2
fi

# 清理
rm -f run_qemu.sh

echo "=============================================="