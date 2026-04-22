import { GET } from '../router.js';
import { request as httpsRequest } from 'node:https';
import { request as httpRequest } from 'node:http';
import { URL } from 'node:url';
import { authMiddleware } from '../middleware/auth.js';

const ALLOWED_HOSTS = [
  'img.nga.178.com',
  'img2.nga.178.com',
  'img4.nga.178.com',
  'img8.nga.cn',
];

GET('/api/image-proxy', async (req, res): Promise<void> => {
  const url = new URL(req.url!, `http://localhost`);
  const imageUrl = url.searchParams.get('url');
  if (!imageUrl) {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Missing url');
    return;
  }

  let targetUrl: URL;
  try {
    targetUrl = new URL(imageUrl);
  } catch {
    res.writeHead(400, { 'Content-Type': 'text/plain' });
    res.end('Invalid url');
    return;
  }

  if (!ALLOWED_HOSTS.some(h => targetUrl.hostname === h || targetUrl.hostname.endsWith('.' + h))) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('Domain not allowed');
    return;
  }

  try {
    const isHttps = targetUrl.protocol === 'https:';
    const requester = isHttps ? httpsRequest : httpRequest;

    const headers: Record<string, string> = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'Referer': 'https://bbs.nga.cn/',
      'Accept': 'image/*,*/*',
    };

    const session = authMiddleware(req);
    if (session) {
      headers['Cookie'] = `ngaPassportUid=${session.uid}; ngaPassportCid=${session.cid}`;
    }

    const proxyReq = requester(targetUrl, {
      method: 'GET',
      headers,
    }, (upstream) => {
      const contentType = upstream.headers['content-type'] || 'application/octet-stream';
      const contentLength = upstream.headers['content-length'];

      if (upstream.statusCode !== 200) {
        res.writeHead(upstream.statusCode ?? 502, {
          'Content-Type': String(upstream.headers['content-type'] || 'text/plain'),
          'Cache-Control': 'public, max-age=300',
          'Access-Control-Allow-Origin': '*',
        });
        upstream.pipe(res);
        return;
      }

      const resHeaders: Record<string, string> = {
        'Content-Type': String(contentType),
        'Cache-Control': 'public, max-age=86400',
        'Access-Control-Allow-Origin': '*',
      };
      if (contentLength) resHeaders['Content-Length'] = String(contentLength);

      res.writeHead(200, resHeaders);
      upstream.pipe(res);
    });

    proxyReq.on('error', (err) => {
      console.error(`[image-proxy] request error:`, err.message);
      if (!res.headersSent) {
        res.writeHead(502, { 'Content-Type': 'text/plain' });
        res.end('Proxy error');
      }
    });

    proxyReq.end();
  } catch {
    res.writeHead(502, { 'Content-Type': 'text/plain' });
    res.end('Proxy error');
  }
});
