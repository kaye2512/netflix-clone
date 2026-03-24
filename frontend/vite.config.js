import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8000',
    },
  },
  preview: {
    port: 5173, // ← même port que server
    host: '0.0.0.0',
    allowedHosts: 'all',
  },
});
