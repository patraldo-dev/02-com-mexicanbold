import { VideoProjectDO } from './durable-objects/VideoProjectDO.js';

export { VideoProjectDO };

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname.startsWith('/project/')) {
      const projectId = url.pathname.split('/')[2];
      const id = env.VIDEO_PROJECTS.idFromName(projectId);
      const stub = env.VIDEO_PROJECTS.get(id);
      return stub.fetch(request);
    }

    return new Response('Video Editor Worker', { status: 200 });
  },
};
