import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import todos from './routes/todos.js';

const app = new Hono();
const PORT = Number(process.env.PORT) || 3000;

app.get('/', (c) =>
  c.json({
    message: 'Todo API',
    version: '2.0.0',
    endpoints: { todos: '/api/todos' },
  })
);

app.route('/api/todos', todos);

serve({ fetch: app.fetch, port: PORT }, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Try: http://localhost:${PORT}/api/todos`);
});
