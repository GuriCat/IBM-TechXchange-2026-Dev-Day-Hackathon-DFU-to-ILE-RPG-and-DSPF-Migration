import { Hono } from 'hono';
import { db } from '../db.js';
import type { CreateTodoInput, UpdateTodoInput } from '../models/todo.js';

const todos = new Hono();

todos.get('/', (c) => {
  return c.json(db.getAll());
});

todos.get('/:id', (c) => {
  const todo = db.getById(c.req.param('id'));
  if (!todo) return c.json({ error: 'Todo not found' }, 404);
  return c.json(todo);
});

todos.post('/', async (c) => {
  const input = await c.req.json<CreateTodoInput>();
  if (!input.title?.trim()) {
    return c.json({ error: 'Title is required' }, 400);
  }
  const todo = db.create(input.title.trim());
  return c.json(todo, 201);
});

todos.put('/:id', async (c) => {
  const input = await c.req.json<UpdateTodoInput>();
  const todo = db.update(c.req.param('id'), input);
  if (!todo) return c.json({ error: 'Todo not found' }, 404);
  return c.json(todo);
});

todos.delete('/:id', (c) => {
  const deleted = db.delete(c.req.param('id'));
  if (!deleted) return c.json({ error: 'Todo not found' }, 404);
  return new Response(null, { status: 204 });
});

export default todos;
