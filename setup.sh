#!/bin/bash
echo "🚀 Setting up iOS dev environment..."

# Install Xcode Command Line Tools
xcode-select --install 2>/dev/null || echo "✅ Xcode tools already installed"

# Install Homebrew
which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install CocoaPods
which pod || sudo gem install cocoapods

# Install SwiftLint
brew install swiftlint 2>/dev/null || echo "✅ SwiftLint already installed"

# Install SwiftFormat
brew install swiftformat 2>/dev/null || echo "✅ SwiftFormat already installed"

# Setup keychain for App Store uploads
echo "💡 Run: security add-generic-password -a 'YOUR_APPLE_ID' -w 'APP_SPECIFIC_PASSWORD' -s 'AC_PASSWORD'"

echo "✅ Setup complete! Run 'SHIP-IT-NOW' task to deploy!"
