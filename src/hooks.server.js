// Export the VideoAppAgent at the module level
export { VideoAppAgent } from '$lib/mcp-agents/VideoAppAgent.js';

/** @type {import('@sveltejs/kit').Handle} */
export async function handle({ event, resolve }) {
  return resolve(event);
}
