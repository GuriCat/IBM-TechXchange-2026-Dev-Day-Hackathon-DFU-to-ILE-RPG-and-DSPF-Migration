import type { Todo } from './models/todo.js';

class TodoDatabase {
  private todos: Map<string, Todo>;

  constructor() {
    this.todos = new Map();
    const sample: Todo = {
      id: crypto.randomUUID(),
      title: 'Learn Node.js modernization',
      completed: false,
      createdAt: new Date(),
    };
    this.todos.set(sample.id, sample);
  }

  getAll(): Todo[] {
    return Array.from(this.todos.values());
  }

  getById(id: string): Todo | undefined {
    return this.todos.get(id);
  }

  create(title: string): Todo {
    const todo: Todo = {
      id: crypto.randomUUID(),
      title,
      completed: false,
      createdAt: new Date(),
    };
    this.todos.set(todo.id, todo);
    return todo;
  }

  update(id: string, updates: { title?: string; completed?: boolean }): Todo | undefined {
    const todo = this.todos.get(id);
    if (!todo) return undefined;
    const updated = { ...todo, ...updates };
    this.todos.set(id, updated);
    return updated;
  }

  delete(id: string): boolean {
    return this.todos.delete(id);
  }
}

export const db = new TodoDatabase();
