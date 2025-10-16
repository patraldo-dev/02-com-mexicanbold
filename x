// Import the Durable Object class definition (now located inside backend)
import { VideoAppAgent } from './VideoAppAgent.js';  

// Re-export it as a named export exactly as Cloudflare expects
export { VideoAppAgent };

// Export the default fetch handler that routes requests to the Durable Object instances
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const projectId = url.pathname === '/project' ? '02-com-mexicanbold' : 'default';
    const id = env.VIDEO_APP_AGENT.idFromName(projectId);
    const stub = env.VIDEO_APP_AGENT.get(id);
    return stub.fetch(request);
  }
};

