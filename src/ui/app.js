const http = require('http')
const https = require('https')
const static = require('node-static')
const space = require('space-client-js')

const hostname = '0.0.0.0'
const port = 8080
const staticFiles = new static.Server(__dirname, { cache: 0 })
const spaceApi = new space.TleApi(
    new space.ApiClient(basePath='https://api.thiago.pub'))

function orbit(name, line1, line2, out) {
  var tleOrbitReq = new space.TleToOrbitReq()
  tleOrbitReq.tleData = new space.TleData()
  tleOrbitReq.tleData.name = name
  tleOrbitReq.tleData.line1 = line1
  tleOrbitReq.tleData.line2 = line2
  var callback = function(error, data, response) {
    if (error) {
      console.error(error)
    } else {
      out.writeHead(200, {'Content-Type': 'text/plain; charset=utf-8'})
      out.end(data.orbit)
    }
  };
  spaceApi.tleToOrbit(tleOrbitReq, callback)
}

const server = http.createServer((req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
  res.setHeader('Pragma', 'no-cache')

  if (req.url === '/submit' && req.method === 'POST') {
    let body = ''
    req.on('data', chunk => {
      body += chunk.toString(); // convert Buffer to string
    })
    req.on('end', () => {
      /* This is pretty ludicrous, but it's the best I could get to.

       Form posts with Content-Type 'multipart/form-data', so body looks like
       -----------------------------23605125921461961015802936950
       Content-Disposition: form-data; name="tle"

       ISS (ZARYA)
       1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996
       2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05
       -----------------------------23605125921461961015802936950--

       I didn't find a reasonable parser for that, so I simply retrieve the lines
       I need from the body (lines 3 to 5) and trim them to remove the carriage return
       characters.
       */
      const bodyParts = body.split('\n')
      const name = bodyParts[3].trim().trimLeft()
      const line1 = bodyParts[4].trim().trimLeft()
      const line2 = bodyParts[5].trim().trimLeft()
      orbit(name, line1, line2, res)
    })
  } else {
    staticFiles.serve(req, res)
  }
})

server.listen(port, hostname, () => {
  console.log(`UI server running on http://${hostname}:${port}/`)
})
