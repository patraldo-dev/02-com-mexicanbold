// src/entrypoint.js
import { VideoAppAgent } from './lib/mcp-agents/VideoAppAgent.js';

// Re-export the Agent as a Durable Object class
export { VideoAppAgent };

// Also export the default handler for SvelteKit
export { default } from './server.js';
