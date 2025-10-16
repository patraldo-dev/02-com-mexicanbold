// svelte.config.js
import adapter from "@sveltejs/adapter-cloudflare";

/** @type {import('@sveltejs/kit').Config} */
const config = {
  kit: {
    adapter: adapter({
      // 👇 This tells the adapter to use your custom entrypoint
      entrypoints: {
        worker: 'src/worker-entrypoint.js'
      }
    })
  }
};

export default config;
