// src/routes/api/project/+server.js
export async function GET() {
  const backendUrl = 'https://02-com-mexianbold-backend.chef-tech.workers.dev/project';
  const resp = await fetch(backendUrl);
  return new Response(resp.body, resp);
}

export async function PUT({ request }) {
  const backendUrl = 'https://02-com-mexicanbold-backend.chef-tech.workers.dev/project';
  const resp = await fetch(backendUrl, {
    method: 'PUT',
    headers: request.headers,
    body: request.body
  });
  return new Response(resp.body, resp);
}
