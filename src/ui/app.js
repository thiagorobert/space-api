const http = require('http')
const https = require('https')
const fs = require('fs');
const space = require('space-client-js')
const static = require('node-static')
const mustache = require('mustache')

const hostname = '0.0.0.0'
const port = 8080
const staticFiles = new static.Server(__dirname, { cache: 0 })

function getSpaceApiEndpoint() {
  let spaceApiEndpoint = 'https://api.thiago.pub'
  const inputFlags = require('process').argv.slice(2)
  const minFlags = require('minimist')(inputFlags)
  if ('space_api_endpoint' in minFlags) {
    spaceApiEndpoint = minFlags['space_api_endpoint']
  }
  console.log(`UI using Space Api at '${spaceApiEndpoint}'`)
}

const spaceApi = new space.TleApi(new space.ApiClient(basePath=getSpaceApiEndpoint()))

let template
fs.readFile(__dirname + '/index.html', 'utf-8', function (err, data) {
  if (err) {
    return console.error(err)
  }
  template = data
})

function bodyToTleData(body) {
  const tleData = new space.TleData()
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
  tleData.name = bodyParts[3].trim().trimLeft()
  tleData.line1 = bodyParts[4].trim().trimLeft()
  tleData.line2 = bodyParts[5].trim().trimLeft()
  return tleData
}

function decodedToHtml(decoded) {
  let out = decoded.replace('TLE(', '<br /><b>')
  out = out.replace(/=/g, ':</b> ')
  return '<b>TLE:</b>' + out.replace(/, /g, '<br /><b>').slice(0, -1)
}

function process(tleData, out) {
  const decodeReq = new space.TleToOrbitReq()
  decodeReq.tleData = tleData
  let decoded = ''
  spaceApi.tleDecode(decodeReq, function(error, data, response) {
    if (error) {
      console.error(error)
    } else {
      decoded = data.decoded
    }
  })

  const toOrbitReq = new space.TleToOrbitReq()
  toOrbitReq.tleData = tleData
  spaceApi.tleToOrbit(toOrbitReq, async function(error, data, response) {
    if (error) {
      console.error(error)
    } else {
      out.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'})
      // TODO: adding a delay to ensure this returns in time to be rendered; should be a promisse.
      await new Promise(r => setTimeout(r, 500));
      const rendered = mustache.render(template,
          {
            tle: [tleData.name, tleData.line1, tleData.line2].join('\n'),
            decoded: decodedToHtml(decoded),
            orbit: '<b>Orbit:</b> ' + data.orbit,
            visualization: '<iframe class="orbit-visualization" src="http://api.thiago.pub:9091"></iframe>'
          })
      out.end(rendered)
    }
  })
}

const server = http.createServer((req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
  res.setHeader('Pragma', 'no-cache')

  if (req.url === '/' && req.method === 'GET') {
    res.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'})
    const rendered = mustache.render(template, {})
    res.end(rendered)
  } else if (req.url === '/submit' && req.method === 'POST') {
    let body = ''
    req.on('data', chunk => {
      body += chunk.toString()
    })
    req.on('end', () => {
      process(bodyToTleData(body), res)
    })
  } else {
    staticFiles.serve(req, res)
  }
})

server.listen(port, hostname, () => {
  console.log(`UI server running on http://${hostname}:${port}/`)
})
