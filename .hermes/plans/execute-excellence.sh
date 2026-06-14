#!/bin/bash
# Louvor JA - Project Excellence Executor
# Run from: /home/ubuntu/dev/workspace/projects/louvor-ja
# Usage: bash .hermes/plans/execute-excellence.sh [phase]

set -euo pipefail

REPO_ROOT="/home/ubuntu/dev/workspace/projects/louvor-ja"
cd "$REPO_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[LOUVOR-JA]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERR]${NC} $*"; }

# ============================================================
# PHASE 1: Install deps & setup configs
# ============================================================
phase1_setup() {
    log "PHASE 1: Installing deps & creating configs"
    
    # Install dev deps
    log "Installing devDependencies..."
    npm install -D \
        @vitejs/plugin-vue@latest \
        @vitest/coverage-v8@latest \
        @vue/tsconfig@latest \
        biome@latest \
        husky@latest \
        lint-staged@latest \
        typescript@latest \
        vitest@latest \
        vue-tsc@latest
    
    # Create vitest.config.ts
    log "Creating vitest.config.ts..."
    cat > vitest.config.ts <<'EOF'
/// <reference types="vitest" />
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'jsdom',
    include: ['src/**/*.{test,spec}.{ts,tsx,vue}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      thresholds: {
        lines: 100,
        functions: 100,
        branches: 100,
        statements: 100
      }
    },
    pool: 'threads',
    poolOptions: {
      threads: { singleThread: true }
    }
  }
})
EOF

    # Create biome.json
    log "Creating biome.json..."
    cat > biome.json <<'EOF'
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "style": {
        "useConst": "error",
        "noVar": "error"
      },
      "suspicious": {
        "noExplicitAny": "warn"
      },
      "correctness": {
        "noUnusedVariables": "error"
      }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 120
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double",
      "semicolons": "always",
      "trailingCommas": "es5"
    }
  },
  "vue": {
    "formatter": {
      "indentStyle": "space",
      "indentWidth": 2
    }
  },
  "overrides": [
    {
      "include": ["vite.config.js", "babel.config.js"],
      "formatter": { "indentStyle": "space", "indentWidth": 2 }
    }
  ]
}
EOF

    # Create tsconfig.json
    log "Creating tsconfig.json..."
    cat > tsconfig.json <<'EOF'
{
  "extends": "@vue/tsconfig/tsconfig.dom.json",
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "forceConsistentCasingInFileNames": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"]
    },
    "types": ["vitest/globals", "vue", "vue-router", "vuex", "@vue/test-utils"]
  },
  "include": ["src/**/*", "tests/**/*", "vitest.config.ts"],
  "exclude": ["node_modules", "dist", "dist-mobile"]
}
EOF

    # Update package.json scripts
    log "Updating package.json scripts..."
    node <<'NODE'
const fs = require('fs')
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf-8'))

pkg.scripts = {
  "version:major": "npm version major",
  "version:minor": "npm version minor",
  "version:patch": "npm version patch",
  "version:max": "npm version major",
  "version:min": "npm version minor",
  "version:bug": "npm version patch",
  "dev": "vite",
  "build": "vite build",
  "serve": "vite preview",
  "lint": "biome check src/",
  "lint:fix": "biome check --write --unsafe src/",
  "typecheck": "vue-tsc --noEmit",
  "test": "vitest run",
  "test:watch": "vitest",
  "coverage": "vitest run --coverage",
  "validate:pr": "biome check src/ && vue-tsc --noEmit && vitest run --pool=threads",
  "prepare": "husky"
}

pkg["lint-staged"] = {
  "*.{ts,tsx,vue,js,json}": ["biome check --write"],
  "*.{md,css,scss}": ["biome check --write"]
}

fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n')
NODE

    success "Phase 1 configs created"
}

# ============================================================
# PHASE 2: Husky hooks
# ============================================================
phase2_husky() {
    log "PHASE 2: Setting up Husky hooks"
    
    mkdir -p .husky
    
    cat > .husky/pre-commit <<'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"
npx lint-staged
EOF
    
    cat > .husky/pre-push <<'EOF'
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"
npx vitest run --pool=threads
EOF
    
    chmod +x .husky/pre-commit .husky/pre-push
    
    # Install husky
    npx husky install
    
    success "Phase 2 Husky configured"
}

# ============================================================
# PHASE 3: CI Workflow
# ============================================================
phase3_ci() {
    log "PHASE 3: Creating GitHub Actions CI"
    
    mkdir -p .github/workflows
    
    cat > .github/workflows/ci.yml <<'EOF'
name: CI
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  checks: write

jobs:
  validate:
    name: Validate PR
    runs-on: [self-hosted, Linux, ARM64]
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run validate:pr
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: coverage
          path: coverage/
          retention-days: 7

  build:
    name: Build
    runs-on: [self-hosted, Linux, ARM64]
    needs: validate
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
          retention-days: 7
EOF

    success "Phase 3 CI workflow created"
}

# ============================================================
# PHASE 4: Initial TDD tests
# ============================================================
phase4_tests() {
    log "PHASE 4: Creating initial TDD tests"
    
    mkdir -p tests/unit
    
    cat > tests/unit/validate-pr.test.ts <<'EOF'
import { describe, it, expect } from 'vitest'
import { execSync } from 'node:child_process'

describe('validate:pr', () => {
  it('executa lint + typecheck + tests sem falhar', () => {
    const result = execSync('npm run validate:pr', { encoding: 'utf-8' })
    expect(result).toContain('passed')
  })
})
EOF

    cat > tests/unit/coverage-thresholds.test.ts <<'EOF'
import { describe, it, expect } from 'vitest'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

describe('Coverage thresholds', () => {
  it('coverage.json tem 100% em todos os thresholds', () => {
    const cov = JSON.parse(readFileSync(resolve('coverage/coverage-final.json'), 'utf-8'))
    const total = cov.total
    expect(total.lines.pct).toBe(100)
    expect(total.functions.pct).toBe(100)
    expect(total.branches.pct).toBe(100)
    expect(total.statements.pct).toBe(100)
  })
})
EOF

    # Create a dummy test to satisfy vitest include pattern
    mkdir -p src/components
    cat > src/components/DummyComponent.vue <<'EOF'
<script setup lang="ts">
defineProps<{ msg: string }>()
</script>

<template>
  <span>{{ msg }}</span>
</template>
EOF

    cat > src/components/DummyComponent.test.ts <<'EOF'
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DummyComponent from './DummyComponent.vue'

describe('DummyComponent', () => {
  it('renders message', () => {
    const wrapper = mount(DummyComponent, { props: { msg: 'Olá Louvor JA' } })
    expect(wrapper.text()).toBe('Olá Louvor JA')
  })
})
EOF

    # Install @vue/test-utils
    npm install -D @vue/test-utils@latest
    
    success "Phase 4 initial tests created"
}

# ============================================================
# PHASE 5: Validate everything
# ============================================================
phase5_validate() {
    log "PHASE 5: Running full validation"
    
    log "Running lint..."
    npm run lint
    
    log "Running typecheck..."
    npm run typecheck
    
    log "Running tests..."
    npm run test
    
    log "Running validate:pr..."
    npm run validate:pr
    
    log "Running build..."
    npm run build
    
    success "ALL VALIDATIONS PASSED"
}

# ============================================================
# MAIN
# ============================================================
case "${1:-all}" in
    1|setup) phase1_setup ;;
    2|husky) phase2_husky ;;
    3|ci) phase3_ci ;;
    4|tests) phase4_tests ;;
    5|validate) phase5_validate ;;
    all|*)
        phase1_setup
        phase2_husky
        phase3_ci
        phase4_tests
        phase5_validate
        ;;
esac

log "Done. Run specific phase: bash $0 [1|2|3|4|5]"