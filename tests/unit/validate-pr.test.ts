import { describe, it, expect } from 'vitest'
import { execSync } from 'node:child_process'

describe('validate:pr', () => {
  it('executa lint + typecheck + tests sem falhar', () => {
    const result = execSync('npm run validate:pr', { encoding: 'utf-8' })
    expect(result).toContain('passed')
  })
})
