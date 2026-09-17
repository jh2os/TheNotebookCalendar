import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue' // 1. Import the plugin

export default defineConfig({
  plugins: [
    RubyPlugin(),

  ],
})
