# Dockerfile for Swift tests on Linux
FROM swift:5.10-focal AS swift-base

# Install dependencies
RUN apt-get update && apt-get install -y \
    clang \
    libxml2-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files (for caching)
COPY Package.swift .
COPY Package.resolved .

# Copy source code
COPY Sources/ Sources/
COPY Tests/ Tests/

# Resolve dependencies (cached layer)
RUN swift package resolve

# Default command: run tests
CMD ["swift", "test", "--enable-code-coverage"]
