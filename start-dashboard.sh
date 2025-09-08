#!/bin/bash

echo "🚀 Starting LHI Sync Dashboard..."
echo ""
echo "======================================"
echo "   LIFEHACK INNOVATIONS LLC"
echo "   Multi-Environment Sync Dashboard"
echo "======================================"
echo ""

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo "✅ Dashboard starting on port 7001..."
echo "📊 Access at: http://localhost:7001"
echo ""
echo "Features:"
echo "  - Real-time sync status"
echo "  - Manual sync instructions"
echo "  - Environment detection"
echo "  - Auto-refresh every 30 seconds"
echo ""
echo "Press Ctrl+C to stop the dashboard"
echo ""

# Start the server
npm start