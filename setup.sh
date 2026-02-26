#!/bin/bash
set -e

echo "🚀 Setting up StackedOllama iOS dev environment..."
echo ""

# Detect OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "✅ macOS detected - Full iOS setup"
    IS_MAC=true
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Linux detected - Remote dev setup"
    IS_MAC=false
else
    echo "❌ Unsupported OS"
    exit 1
fi

# macOS Setup
if [ "$IS_MAC" = true ]; then
    # Install Xcode Command Line Tools
    if ! xcode-select -p &> /dev/null; then
        echo "📦 Installing Xcode Command Line Tools..."
        xcode-select --install
        echo "⏳ Please complete Xcode tools installation and re-run this script"
        exit 0
    else
        echo "✅ Xcode Command Line Tools installed"
    fi

    # Install Homebrew
    if ! which brew &> /dev/null; then
        echo "🍺 Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "✅ Homebrew installed"
    fi

    # Install CocoaPods
    if ! which pod &> /dev/null; then
        echo "📦 Installing CocoaPods..."
        sudo gem install cocoapods
    else
        echo "✅ CocoaPods installed"
    fi

    # Install dependencies
    echo "📦 Installing development tools..."
    brew install swiftlint swiftformat xcbeautify 2>/dev/null || echo "✅ Tools already installed"

    # Install fastlane
    if ! which fastlane &> /dev/null; then
        echo "🚀 Installing Fastlane..."
        brew install fastlane
    else
        echo "✅ Fastlane installed"
    fi

    # Setup CocoaPods if Podfile exists
    if [ -f "Podfile" ]; then
        echo "📦 Installing CocoaPods dependencies..."
        pod install
    fi

    # Open Xcode project
    if [ -f "StackedOllama.xcworkspace" ]; then
        echo "📱 Opening Xcode workspace..."
        open StackedOllama.xcworkspace
    elif [ -f "StackedOllama.xcodeproj" ]; then
        echo "📱 Opening Xcode project..."
        open StackedOllama.xcodeproj
    fi

    echo ""
    echo "🔐 App Store Upload Setup:"
    echo "Run: security add-generic-password -a 'YOUR_APPLE_ID' -w 'APP_SPECIFIC_PASSWORD' -s 'AC_PASSWORD'"
    echo ""
    echo "✅ macOS setup complete!"
    echo "🚀 Run 'SHIP-IT-NOW' task in VS Code to deploy!"

# Linux Setup
else
    echo "🐧 Setting up Linux development environment..."
    
    # Install Swift
    if ! which swift &> /dev/null; then
        echo "📦 Installing Swift..."
        wget https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
        tar xzf swift-5.9.2-RELEASE-ubuntu22.04.tar.gz
        sudo mv swift-5.9.2-RELEASE-ubuntu22.04 /usr/share/swift
        echo 'export PATH=/usr/share/swift/usr/bin:$PATH' >> ~/.bashrc
        source ~/.bashrc
    else
        echo "✅ Swift installed"
    fi

    # Install LLDB
    if ! which lldb &> /dev/null; then
        echo "🐛 Installing LLDB..."
        sudo apt-get update
        sudo apt-get install -y lldb
    else
        echo "✅ LLDB installed"
    fi

    # Install rsync for syncing to Mac
    if ! which rsync &> /dev/null; then
        echo "🔄 Installing rsync..."
        sudo apt-get install -y rsync
    else
        echo "✅ rsync installed"
    fi

    echo ""
    echo "🔗 Remote Mac Setup:"
    echo "1. Update 'sync-to-mac' task in .vscode/tasks.json with your Mac IP"
    echo "2. Setup SSH key: ssh-copy-id user@mac-ip"
    echo "3. Run 'sync-to-mac' task to push code to Mac"
    echo ""
    echo "✅ Linux setup complete!"
fi

echo ""
echo "🎉 All done! Happy coding!"
