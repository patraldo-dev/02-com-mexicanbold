// svelte.config.js
import adapter from '@sveltejs/adapter-cloudflare';

export default {
  kit: {
    adapter: adapter({
      // Use custom entrypoint
      entrypoints: {
        worker: 'src/entrypoint.js'
      }
    })
  }
};
