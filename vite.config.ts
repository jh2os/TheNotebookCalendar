import { defineConfig, loadEnv } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue' // 1. Import the plugin

export default defineConfig(({ mode }) => {
  const { APP_HOST: appHost = 'localhost' } = loadEnv(mode, '.', '')

  return {
    plugins: [
      RubyPlugin(),
      vue(),
    ],
    server: {
      host: '0.0.0.0',
      cors: {
        origin: [`http://${appHost}:3000`],
      },
      hmr: {
        host: appHost,
      },
    },
  }
})
