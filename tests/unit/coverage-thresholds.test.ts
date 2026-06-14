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
