import { createServer } from 'node:http';
import { router } from './router.js';
import './api/auth.js';
import './api/forum.js';
import './api/topic.js';
import './api/thread.js';
import './api/image-proxy.js';
import './api/write.js';
import './api/browse-history.js';

const PORT = parseInt(process.env.PORT ?? '3050', 10);

createServer(async (req, res) => {
  try {
    await router(req, res);
  } catch (err) {
    console.error('Unhandled error:', err);
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Internal Server Error' }));
  }
}).listen(PORT, () => {
  console.log(`Server running at http://localhost:${PORT}`);
});
