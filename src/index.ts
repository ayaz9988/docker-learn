import express from "express";
import Redis from "ioredis";
import db from "./db";

const app = express();
app.use(express.json());

const redis = new Redis(process.env.REDIS_URL || "redis://localhost:6379");

// ── GET / ──────────────────────────────────────────────────────────────────
app.get("/", (_req, res) => {
  res.json({ message: "Hello, world!" });
});

// ── GET /tasks ─────────────────────────────────────────────────────────────
// Returns the full task list, cached in Redis for 30 seconds.
app.get("/tasks", async (_req, res) => {
  try {
    const cached = await redis.get("tasks:list");
    if (cached) {
      res.json(JSON.parse(cached));
      return;
    }
  } catch {
    // Redis down — fall through to DB query
  }

  const tasks = db.prepare("SELECT * FROM tasks ORDER BY created_at DESC").all();

  try {
    await redis.setex("tasks:list", 30, JSON.stringify(tasks));
  } catch {
    // Non-critical cache write failure
  }

  res.json(tasks);
});

// ── POST /tasks ────────────────────────────────────────────────────────────
// Creates a task and invalidates the cached task list.
app.post("/tasks", async (req, res) => {
  const { title } = req.body;
  if (!title || typeof title !== "string") {
    res.status(400).json({ error: "title is required" });
    return;
  }

  const stmt = db.prepare("INSERT INTO tasks (title) VALUES (?)");
  const result = stmt.run(title);
  const task = db.prepare("SELECT * FROM tasks WHERE id = ?").get(result.lastInsertRowid);

  // Invalidate the list cache so next GET /tasks fetches fresh data
  try {
    await redis.del("tasks:list");
  } catch {
    // Non-critical
  }

  res.status(201).json(task);
});

// ── GET /tasks/:id ─────────────────────────────────────────────────────────
// Returns a single task, cached in Redis for 30 seconds.
app.get("/tasks/:id", async (req, res) => {
  const id = Number.parseInt(req.params.id);
  if (Number.isNaN(id)) {
    res.status(400).json({ error: "invalid id" });
    return;
  }

  try {
    const cached = await redis.get(`tasks:${id}`);
    if (cached) {
      res.json(JSON.parse(cached));
      return;
    }
  } catch {
    // Redis down — fall through
  }

  const task = db.prepare("SELECT * FROM tasks WHERE id = ?").get(id);
  if (!task) {
    res.status(404).json({ error: "not found" });
    return;
  }

  try {
    await redis.setex(`tasks:${id}`, 30, JSON.stringify(task));
  } catch {
    // Non-critical
  }

  res.json(task);
});

// ── Server start ───────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`listening on http://localhost:${PORT}`);
});
