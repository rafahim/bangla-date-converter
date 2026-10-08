import http from 'node:http'
import { readFile } from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { gregorianToBangla, banglaToGregorian, toISODate } from '../calendar.js'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const port = Number(process.env.PORT || 4173)
const types = { '.html': 'text/html; charset=utf-8', '.css': 'text/css; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.json': 'application/json; charset=utf-8', '.svg': 'image/svg+xml', '.txt': 'text/plain; charset=utf-8', '.xml': 'application/xml; charset=utf-8', '.webmanifest': 'application/manifest+json; charset=utf-8' }

function send(response, status, body, contentType = 'application/json; charset=utf-8') {
  response.writeHead(status, { 'content-type': contentType, 'x-content-type-options': 'nosniff', 'referrer-policy': 'strict-origin-when-cross-origin', 'cache-control': 'no-store' })
  response.end(typeof body === 'string' ? body : JSON.stringify(body))
}

function handleApi(url, response) {
  if (url.pathname === '/api/health') return send(response, 200, { ok: true, name: 'Bangla Date Converter' })
  if (url.pathname !== '/api/convert') return send(response, 404, { error: 'API endpoint not found' })
  try {
    const type = url.searchParams.get('type') || 'to-bangla'
    if (type === 'to-bangla' || type === 'gregorian') {
      const date = url.searchParams.get('date')
      if (!date) return send(response, 400, { error: 'date=YYYY-MM-DD is required' })
      return send(response, 200, { gregorian: toISODate(date), bangla: gregorianToBangla(date) })
    }
    if (type === 'to-gregorian' || type === 'bangla') {
      const year = url.searchParams.get('year')
      const month = url.searchParams.get('month')
      const day = url.searchParams.get('day')
      if (!year || !month || !day) return send(response, 400, { error: 'year, month and day are required' })
      const gregorian = toISODate(banglaToGregorian(year, month, day))
      return send(response, 200, { gregorian, bangla: gregorianToBangla(gregorian) })
    }
    return send(response, 400, { error: 'type must be to-bangla or to-gregorian' })
  } catch (error) {
    return send(response, 400, { error: error.message || 'Unable to convert date' })
  }
}

const server = http.createServer(async (request, response) => {
  const url = new URL(request.url || '/', `http://${request.headers.host || 'localhost'}`)
  if (url.pathname.startsWith('/api/')) return handleApi(url, response)
  if (request.method !== 'GET' && request.method !== 'HEAD') return send(response, 405, { error: 'Method not allowed' })
  let pathname
  try { pathname = decodeURIComponent(url.pathname) } catch { return send(response, 400, { error: 'Invalid path' }) }
  if (pathname === '/') pathname = '/index.html'
  const filePath = path.resolve(root, `.${pathname}`)
  if (filePath !== root && !filePath.startsWith(`${root}${path.sep}`)) return send(response, 403, { error: 'Forbidden' })
  try {
    const body = await readFile(filePath)
    response.writeHead(200, { 'content-type': types[path.extname(filePath)] || 'application/octet-stream', 'x-content-type-options': 'nosniff', 'referrer-policy': 'strict-origin-when-cross-origin', 'cache-control': 'no-cache' })
    response.end(request.method === 'HEAD' ? undefined : body)
  } catch {
    send(response, 404, 'Not found', 'text/plain; charset=utf-8')
  }
})

server.listen(port, '127.0.0.1', () => process.stdout.write(`Bangla Date Converter running at http://127.0.0.1:${port}\n`))
