import { IncomingMessage, ServerResponse } from 'node:http';
import { serveStatic } from './middleware/static.js';
import { corsMiddleware } from './middleware/cors.js';
import { initSnapshot, snapAls, createSnapStore, buildAndWriteSnap, isEnabled } from './lib/snapshot.js';

initSnapshot();

type RouteHandler = (req: IncomingMessage, res: ServerResponse, params: Record<string, string>) => Promise<void> | void;
interface Route {
  method: string;
  pattern: RegExp;
  handler: RouteHandler;
  paramNames: string[];
}

const routes: Route[] = [];

function addRoute(method: string, path: string, handler: RouteHandler) {
  const paramNames: string[] = [];
  const pattern = path.replace(/:(\w+)/g, (_, name) => {
    paramNames.push(name);
    return '([^/]+)';
  });
  routes.push({ method, pattern: new RegExp(`^${pattern}$`), handler, paramNames });
}

export function GET(path: string, handler: RouteHandler) {
  addRoute('GET', path, handler);
}

export function POST(path: string, handler: RouteHandler) {
  addRoute('POST', path, handler);
}

function extractReqParams(url: URL): Record<string, string> {
  const params: Record<string, string> = {};
  url.searchParams.forEach((v, k) => { params[k] = v; });
  return params;
}

export async function router(req: IncomingMessage, res: ServerResponse) {
  if (corsMiddleware(req, res)) return;

  const url = new URL(req.url!, 'http://localhost');
  const path = url.pathname;
  const method = req.method!;

  if (path.startsWith('/api/')) {
    for (const route of routes) {
      if (route.method !== method) continue;
      const match = path.match(route.pattern);
      if (match) {
        const params: Record<string, string> = {};
        route.paramNames.forEach((name, i) => {
          params[name] = decodeURIComponent(match[i + 1]);
        });

        if (!isEnabled()) {
          return route.handler(req, res, params);
        }

        const reqParams = extractReqParams(url);
        const store = createSnapStore(path, reqParams);

        let capturedBody: string | null = null;
        const origWriteHead = res.writeHead.bind(res);
        const origEnd = res.end.bind(res);

        (res as any).writeHead = function(statusCode: number, headers?: any) {
          if (headers) {
            headers['X-Snap-Id'] = store.snapId;
          } else {
            headers = { 'X-Snap-Id': store.snapId };
          }
          return origWriteHead(statusCode, headers);
        };

        (res as any).end = function(chunk: any) {
          if (typeof chunk === 'string') capturedBody = chunk;
          return origEnd(chunk);
        };

        let snapWritten = false;
        try {
          await snapAls.run(store, () => route.handler(req, res, params));
        } catch (err: any) {
          buildAndWriteSnap(store, null, true, err.message);
          snapWritten = true;
          throw err;
        } finally {
          if (!snapWritten) {
            let responseToClient: any = null;
            if (capturedBody) {
              try { responseToClient = JSON.parse(capturedBody); } catch {}
            }
            const hasError = responseToClient?.ok === false || responseToClient?.error;
            buildAndWriteSnap(
              store,
              responseToClient,
              !!hasError,
              hasError ? (responseToClient?.error ?? undefined) : undefined,
            );
          }
          (res as any).writeHead = origWriteHead;
          (res as any).end = origEnd;
        }
        return;
      }
    }
    res.writeHead(404, { 'Content-Type': 'application/json' });
    return res.end(JSON.stringify({ error: 'Not Found' }));
  }

  return serveStatic(req, res);
}
