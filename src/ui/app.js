const http = require('http')
const https = require('https')
var fs = require('fs');

const hostname = '0.0.0.0';
const port = 8080;

const data = new TextEncoder().encode(
    JSON.stringify({
      tle_data: {
        name: "ISS (ZARYA)",
        line1: "1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996",
        line2: "2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05"
      }
    })
)

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

let orbit = '';

const req = https.request(options, res => {
  console.log(`statusCode: ${res.statusCode}`)

  res.on('data', d => {
    orbit = d
  })
})

req.on('error', error => {
  console.error(error)
})

req.write(data)
req.end()

const server = http.createServer((req, res) => {
  console.log(orbit);
  res.writeHead(200, { 'content-type': 'text/html' })
  fs.createReadStream('src/ui/index.html').pipe(res)
});

server.listen(port, hostname, () => {
  console.log(`UI server running on http://${hostname}:${port}/`);
});
