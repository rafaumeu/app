import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import DummyComponent from './DummyComponent.vue'

describe('DummyComponent', () => {
  it('renders message', () => {
    const wrapper = mount(DummyComponent, { props: { msg: 'Olá Louvor JA' } })
    expect(wrapper.text()).toBe('Olá Louvor JA')
  })
})
