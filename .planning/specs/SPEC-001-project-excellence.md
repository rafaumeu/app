# SPEC-001: Louvor JA — Project Excellence Setup

## O QUE É
Configurar o projeto Louvor JA (Vue 3 + Vuetify + Vite PWA) com padrão de excelência obrigatório: Biome, Husky, validate:pr, CI self-hosted, coverage 100%.

---

## ESTADO ATUAL
- **Stack**: Vue 3.5 + Vuetify 4 + Vite 7 + Vue Router 5 + Vuex 4 + Vue i18n 11
- **PWA**: vite-plugin-pwa configurado
- **Lint**: ESLite (plugin:vue/vue3-essential) — **precisa migrar para Biome**
- **Tests**: **NENHUM** (vitest não instalado)
- **CI**: GitHub Actions — verificar `.github/workflows/`
- **Husky**: **NÃO CONFIGURADO**

---

## DEPENDÊNCIAS
- Node 20+ (Oracle ARM64)
- pnpm ou npm (package-lock.json presente)

---

## O QUE CRIAR

### 1. vitest.config.ts (raiz)
```typescript
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
```

### 2. biome.json (raiz)
```json
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
```

### 3. package.json — scripts atualizados
```json
{
  "scripts": {
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
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^6.0.4",
    "@vitest/coverage-v8": "^2.1.0",
    "@vue/tsconfig": "^0.7.0",
    "biome": "^1.9.4",
    "eslint": "^9.39.3",
    "eslint-plugin-vue": "^9.33.0",
    "husky": "^9.1.6",
    "lint-staged": "^15.2.0",
    "sass": "^1.83.0",
    "typescript": "^5.6.0",
    "vite": "^7.3.1",
    "vite-plugin-pwa": "^1.2.0",
    "vite-plugin-vuetify": "^2.1.3",
    "vitest": "^2.1.0",
    "vue-tsc": "^2.1.0"
  },
  "lint-staged": {
    "*.{ts,tsx,vue,js,json}": ["biome check --write"],
    "*.{md,css,scss}": ["biome check --write"]
  }
}
```

### 4. Husky hooks
```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"
npx lint-staged
```

```bash
# .husky/pre-push
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"
npx vitest run --pool=threads
```

### 5. tsconfig.json (raiz) — estrito
```json
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
```

### 6. GitHub Actions CI (`.github/workflows/ci.yml`)
```yaml
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
```

---

## TESTES DERIVADOS (TDD)

### Teste 1: validate:pr roda sem erros
```typescript
// tests/unit/validate-pr.test.ts
import { describe, it, expect } from 'vitest'
import { execSync } from 'node:child_process'

describe('validate:pr', () => {
  it('executa lint + typecheck + tests sem falhar', () => {
    const result = execSync('npm run validate:pr', { encoding: 'utf-8' })
    expect(result).toContain('passed')
  })
})
```

### Teste 2: Coverage 100%
```typescript
// tests/unit/coverage-thresholds.test.ts
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
```

---

## ARMADILHAS
- **Biome + Vue**: precisa `@biomejs/plugin-vue` ou overrides para `.vue`
- **Vitest + Vue**: precisa `@vitejs/plugin-vue` no config de teste + `environment: 'jsdom'`
- **Husky v9+**: formato sem shebang `#!/usr/bin/env sh` + source `_/husky.sh`
- **ARM64 Oracle**: CPU throttling varia — `pool: threads` + `singleThread: true` evita OOM
- **PWA**: `vite-plugin-pwa` gera SW — testar build offline
- **vue-tsc**: usa `vue-tsc --noEmit` para typecheck (não `tsc`)

---

## CRITÉRIO DE ACEITE
- [ ] `npm run lint` → 0 erros (Biome)
- [ ] `npm run typecheck` → 0 erros (vue-tsc)
- [ ] `npm run test` → passa (vitest)
- [ ] `npm run coverage` → 100% lines/functions/branches/statements
- [ ] `npm run validate:pr` → exit code 0
- [ ] `git commit` → Husky pre-commit roda lint-staged
- [ ] `git push` → Husky pre-push roda vitest
- [ ] CI GitHub Actions → validate + build passam no runner ARM64

---

## ESTIMATIVA
| Item | LOC | Tempo |
|------|-----|-------|
| vitest.config.ts | ~25 | 5 min |
| biome.json | ~35 | 5 min |
| package.json (deps + scripts) | ~30 | 10 min |
| Husky hooks | ~15 | 5 min |
| tsconfig.json | ~20 | 5 min |
| CI workflow | ~40 | 10 min |
| Testes TDD iniciais | ~50 | 15 min |
| **Total** | **~215** | **~55 min** |

---

## PRÓXIMOS SPECS (pós-setup)
- SPEC-002: i18n structure + lang files (PT-BR/EN/ES)
- SPEC-003: PWA offline-first + cache strategies
- SPEC-004: Vuetify theme customization (brand colors)
- SPEC-005: Component library + Storybook
- SPEC-006: Backend API integration (hinos, letras, cifras)
- SPEC-007: Search + filtros avançados
- SPEC-008: Favoritos + sincronização cross-device