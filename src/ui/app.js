const http = require('http')
const https = require('https')
const fs = require('fs')
const space = require('space-client-js')
const static = require('node-static')
const mustache = require('mustache')

function getInputFlags() {
  const inputFlags = require('process').argv.slice(2)
  return require('minimist')(inputFlags)
}
const inputFlags = getInputFlags()

const hostname = '0.0.0.0'
const port = 8080
const staticFiles = new static.Server(__dirname, { cache: 0 })

function getSpaceApiEndpoint() {
  let endpoint = 'https://api.thiago.pub'  // default to Production.
  if ('space_api_endpoint' in inputFlags) {
    endpoint = inputFlags['space_api_endpoint']
  }
  console.log(`UI using Space Api at '${endpoint}'`)
  return endpoint
}

function getOrbitVisualizerEndpoint() {
  let endpoint = 'http://api.thiago.pub:9091'  // default to Production.
  if ('orbit_visualizer_endpoint' in inputFlags) {
    endpoint = inputFlags['orbit_visualizer_endpoint']
  }
  console.log(`UI using Orbit Visualizer at '${endpoint}'`)
  return endpoint
}

const orbitVisualizerEndpoint = getOrbitVisualizerEndpoint()
const spaceApi = new space.TleApi(new space.ApiClient(basePath=getSpaceApiEndpoint()))
const template = fs.readFileSync(__dirname + '/static/index.template', 'utf-8')

function bodyToTleData(body) {
  const tleData = new space.TleData()
  /* This is pretty ludicrous, but it's the best I could get to.

   Form posts with Content-Type 'multipart/form-data', so body looks like string
   below, with '\r\n'.

   -----------------------------23605125921461961015802936950
   Content-Disposition: form-data; name="tle"

   ISS (ZARYA)
   1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996
   2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05
   -----------------------------23605125921461961015802936950--

   I didn't find a reasonable parser for that, so I simply retrieve the lines
   I need from the body and trim them.
   */
  const bodyParts = body.split('\r\n').filter(e => e)  // Remove empty strings.
  if (bodyParts.length > 5) {
    tleData.name = bodyParts[2].trimLeft().trim()
    tleData.line1 = bodyParts[3].trimLeft().trim()
    tleData.line2 = bodyParts[4].trimLeft().trim()
  }
  return tleData
}

function decodedToHtml(decoded) {
  let out = decoded.replace('TLE(', '<br /><b>')
  out = out.replace(/=/g, ':</b> ')
  return '<b>TLE:</b>' + out.replace(/, /g, '<br /><b>').slice(0, -1)
}

function process(tleData, out) {
  let outError = ''
  const decodePromise = new Promise((resolve, reject) => {
    const decodeReq = new space.TleToOrbitReq()
    decodeReq.tleData = tleData
    spaceApi.tleDecode(decodeReq, function (error, data, response) {
      if (error) {
        console.error(error)
        outError += error
        reject(error)
      } else {
        resolve(data.decoded)
      }
    })
  })

  const orbitPromise = new Promise((resolve, reject) => {
    const toOrbitReq = new space.TleToOrbitReq()
    toOrbitReq.tleData = tleData
    spaceApi.tleToOrbit(toOrbitReq, function (error, data, response) {
      if (error) {
        console.error(error)
        outError += error
        reject(error)
      } else {
        resolve(data.orbit)
      }
    })
  })

  const corridorPromise = new Promise((resolve, reject) => {
    const corridorReq = new space.TleToCorridorReq()
    corridorReq.tleData = tleData
    spaceApi.tleToCorridor(corridorReq, function (error, data, response) {
      if (error) {
        console.error(error)
        outError += error
        reject(error)
      } else {
        resolve(data.corridor)
      }
    })
  })

  Promise.all([decodePromise, orbitPromise, corridorPromise]).then((values) => {
    const decoded = values[0]
    const orbit = values[1]
    const corridor = values[2]
    out.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'})
    const rendered = mustache.render(template,
        {
          error: '',
          tle: [tleData.name, tleData.line1, tleData.line2].join('\n'),
          corridor: corridor,
          decoded: decodedToHtml(decoded),
          orbit: '<b>Orbit:</b> ' + orbit,
          visualization: `<iframe class="orbit-visualization" src="${orbitVisualizerEndpoint}"></iframe>`
        })
    out.end(rendered)
  }).catch(function () {
    out.end(mustache.render(template, {error: outError}))
  })
}

const server = http.createServer((req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate')
  res.setHeader('Pragma', 'no-cache')

  if (req.url === '/' && req.method === 'GET') {
    res.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'})
    res.end(mustache.render(template, {}))
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
