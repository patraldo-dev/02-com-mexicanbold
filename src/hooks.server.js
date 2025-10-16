// Export the VideoAppAgent so it's available to the worker
export { VideoAppAgent } from '$lib/mcp-agents/VideoAppAgent.js';

// Optional: Add SvelteKit hooks if you need them
/** @type {import('@sveltejs/kit').Handle} */
export async function handle({ event, resolve }) {
  // You can access the agent binding here if needed
  // event.platform.env.VIDEO_APP_AGENT
  
  return resolve(event);
}
