import { DurableObject } from 'cloudflare:workers';

export class VideoProjectDO extends DurableObject {
  async fetch(request) {
    const url = new URL(request.url);
    
    if (request.method === 'GET' && url.pathname === '/project') {
      let project = await this.ctx.storage.get('project');
      
      if (!project) {
        project = {
          id: this.ctx.id.toString(),
          name: 'Untitled Project',
          clips: [],
          operations: [],
          createdAt: Date.now(),
        };
      }
      
      return Response.json(project);
    }

    return new Response('Not found', { status: 404 });
  }
}
