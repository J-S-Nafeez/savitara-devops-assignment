const test = require('node:test');
const assert = require('node:assert/strict');
const app = require('./server');

test('GET /health returns status 200 and UP status', async () => {
  // Simple mock test server
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/health`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.status, 'UP');
    assert.strictEqual(body.service, 'savitara-devops-app');
    assert.ok(typeof body.timestamp === 'string');
    assert.ok(typeof body.uptime === 'number');
  } finally {
    server.close();
  }
});

test('GET /api/info returns runtime information', async () => {
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/api/info`);
    assert.strictEqual(res.status, 200);

    const body = await res.json();
    assert.strictEqual(body.appName, 'savitara-devops-app');
    assert.strictEqual(body.version, '1.0.0');
    assert.ok(body.hostname);
  } finally {
    server.close();
  }
});

test('GET / returns HTML dashboard with 200', async () => {
  const server = app.listen(0);
  const port = server.address().port;

  try {
    const res = await fetch(`http://127.0.0.1:${port}/`);
    assert.strictEqual(res.status, 200);
    const text = await res.text();
    assert.ok(text.includes('Savitara Infotel'));
    assert.ok(text.includes('DevOps Infrastructure'));
  } finally {
    server.close();
  }
});

