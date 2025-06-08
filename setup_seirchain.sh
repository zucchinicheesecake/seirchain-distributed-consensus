#!/bin/bash

# Enhanced SeirChain Setup Script
# Version: 1.1
# Author: BLACKBOXAI

set -euo pipefail

PROJECT_DIR="${1:-$HOME/seirchain}"
VERBOSE=false
ASSUME_YES=false

REQUIRED_TOOLS=("node" "npm" "openssl" "git" "df")
MIN_NODE_VERSION="14.18.0"
MIN_DISK_SPACE_GB=1

log() {
  local level="$1"
  local message="$2"
  echo "[$level] $message"
}

error_exit() {
  echo "[ERROR] $1" >&2
  exit 1
}

command_exists() {
  command -v "$1" &> /dev/null
}

version_ge() {
  [[ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]
}

check_system_requirements() {
  log INFO "Checking system requirements..."

  for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command_exists "$tool"; then
      error_exit "$tool is required but not installed."
    fi
  done

  local node_version
  node_version=$(node -v | sed 's/v//')
  if ! version_ge "$node_version" "$MIN_NODE_VERSION"; then
    error_exit "Node.js version $MIN_NODE_VERSION or higher is required (found $node_version)."
  fi

  local available_space_gb
  available_space_gb=$(df -BG "$PROJECT_DIR" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
  if [[ -z "$available_space_gb" ]]; then
    available_space_gb=0
  fi
  if (( available_space_gb < MIN_DISK_SPACE_GB )); then
    log WARNING "Less than $MIN_DISK_SPACE_GB GB disk space available in $PROJECT_DIR."
  fi

  log INFO "System requirements check passed."
}

create_project_structure() {
  log INFO "Creating project directory structure at $PROJECT_DIR..."
  mkdir -p "$PROJECT_DIR"
  mkdir -p "$PROJECT_DIR/bin" "$PROJECT_DIR/docs" "$PROJECT_DIR/scripts" "$PROJECT_DIR/src/api" "$PROJECT_DIR/src/cli" "$PROJECT_DIR/src/core" "$PROJECT_DIR/src/ledger" "$PROJECT_DIR/src/network" "$PROJECT_DIR/src/utils" "$PROJECT_DIR/tests/core" "$PROJECT_DIR/data"
  log INFO "Project directories created."
}

create_gitignore() {
  log INFO "Creating .gitignore..."
  cat > "$PROJECT_DIR/.gitignore" << EOF
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
package-lock.json
.env
.env.*
data/
logs/
coverage/
.DS_Store
.idea/
.vscode/
*.log
EOF
  log INFO ".gitignore created."
}

create_jest_config() {
  log INFO "Creating jest.config.js..."
  cat > "$PROJECT_DIR/jest.config.js" << EOF
module.exports = {
  testEnvironment: 'node',
  verbose: true,
  testMatch: ['**/tests/**/*.test.js'],
  collectCoverage: true,
  coverageDirectory: 'coverage',
};
EOF
  log INFO "jest.config.js created."
}

create_package_json() {
  log INFO "Creating package.json..."
  cat > "$PROJECT_DIR/package.json" << EOF
{
  "name": "seirchain",
  "version": "1.0.0",
  "description": "SeirChain TriadMatrix project",
  "main": "src/core/TriadMatrix.js",
  "scripts": {
    "start": "node src/api/server.js",
    "dev": "nodemon src/api/server.js",
    "test": "jest",
    "cli": "node src/cli/seirchain-cli.js",
    "onboard": "node scripts/onboard.js",
    "network": "node src/network/P2PNode.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "dotenv": "^16.0.0",
    "ws": "^8.13.0",
    "nodemailer": "^6.9.0",
    "elliptic": "^6.5.4",
    "level": "^8.0.0",
    "superagent": "9.0.0",
    "bcrypt": "^5.1.0",
    "cors": "^2.8.5",
    "helmet": "^6.0.0",
    "rate-limiter-flexible": "^2.4.0",
    "joi": "^17.9.0",
    "winston": "^3.8.0",
    "lodash": "^4.17.21",
    "uuid": "^9.0.0"
  },
  "devDependencies": {
    "jest": "^29.5.0",
    "nodemon": "^2.0.0"
  }
}
EOF
  log INFO "package.json created."
}

create_env_files() {
  log INFO "Creating .env and .env.production files..."
  cat > "$PROJECT_DIR/.env" << EOF
NODE_ENV=development
PORT=5000
JWT_SECRET=devsecret
EMAIL_ENABLED=false
EOF

  cat > "$PROJECT_DIR/.env.production" << EOF
NODE_ENV=production
PORT=5000
JWT_SECRET=CHANGE_ME_TO_A_STRONG_SECRET
EMAIL_ENABLED=true
EOF
  log INFO "Environment files created."
}

install_dependencies() {
  log INFO "Installing npm dependencies..."
  cd "$PROJECT_DIR"
  npm install
  log INFO "Dependencies installed."
}

show_instructions() {
  echo
  echo "Setup complete!"
  echo "Next steps:"
  echo "1. cd $PROJECT_DIR"
  echo "2. Review and update .env.production with strong secrets."
  echo "3. Run 'npm run dev' to start the development server."
  echo "4. Use 'npm run cli' for CLI commands."
  echo "5. Use 'npm run onboard' to onboard a new node."
  echo "6. Use 'npm run network' to start the P2P network node."
  echo
}

main() {
  check_system_requirements
  create_project_structure
  create_gitignore
  create_jest_config
  create_package_json
  create_env_files
  install_dependencies
  show_instructions
}

main "$@"
