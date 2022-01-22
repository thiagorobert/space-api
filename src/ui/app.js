const http = require('http')
const https = require('https')
const static = require('node-static')

const hostname = '0.0.0.0'
const port = 8080

const data = new TextEncoder().encode(
    JSON.stringify({
      tle_data: {
        name: "ISS (ZARYA)",
        line1: "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996",
        line2: "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"
      }
    })
)

const staticFiles = new static.Server(__dirname, { cache: 0 })

const options = {
  hostname: 'api.thiago.pub',
  port: 443,
  path: '/space/v1/tle/orbit',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
}

function orbit(out) {
  const req = https.request(options, res => {
    res.on('data', d => {
      out.writeHead(200, {'Content-Type': 'text/plain; charset=utf-8'})
      out.end(d.toString())
    })
  })

  req.on('error', error => {
    console.error(error)
  })

  req.write(data)
  req.end()
}

const server = http.createServer((req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
  res.setHeader('Pragma', 'no-cache')

  if (req.url == '/submit') {
    orbit(res)
  } else {
    staticFiles.serve(req, res)
  }
});

server.listen(port, hostname, () => {
  console.log(`UI server running on http://${hostname}:${port}/`)
});
