// Import and re-export the SvelteKit worker
export { default } from '../.svelte-kit/cloudflare/_worker.js';

// Export the VideoAppAgent for Durable Objects
export { VideoAppAgent } from './lib/mcp-agents/VideoAppAgent.js';
