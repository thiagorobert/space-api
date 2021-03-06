import argparse
from concurrent import futures

import grpc
from grpc_health.v1 import health
from grpc_health.v1 import health_pb2
from grpc_health.v1 import health_pb2_grpc
from grpc_reflection.v1alpha import reflection
import corridor_plotter
import orbit_plotter
import proto.unary_pb2_grpc as pb2_grpc
import proto.unary_pb2 as pb2
import tle

_THREAD_POOL_SIZE = 10
_SERVICE_NAMES = (
    pb2.DESCRIPTOR.services_by_name['Tle'].full_name,
    reflection.SERVICE_NAME,
    health.SERVICE_NAME,
)

# Start Orekit to plot corridors.
c = corridor_plotter.Generator()


def inputFlags():
    parser = argparse.ArgumentParser(description='Space API gRPC server')
    parser.add_argument(
        '--server_port', dest='server_port', default='9090', help='gRPC server port')
    parser.add_argument(
        '--dash_port', dest='dash_port', default='9091', help='Dash server port')
    return parser.parse_args()


class TleService(pb2_grpc.TleServicer):
    def Decode(self, request, context):
        decoded = 'ERROR'
        try:
            decoded = tle.Decode(request.tle_data)
        except Exception as e:
            print('Exception type "%s" in Decode()' % type(e).__name__)
            print(e, flush=True)
        result = {'decoded': str(decoded)}
        return pb2.TleDecodeRes(**result)

    def ToOrbit(self, request, context):
        orbit = 'ERROR'
        try:
            orbit = tle.ToOrbit(request.tle_data)
            orbit_plotter.Plot(orbit.plot(use_3d=True, interactive=True))
        except Exception as e:
            print('Exception type "%s" in ToOrbit()' % type(e).__name__)
            print(e, flush=True)
        result = {'orbit': str(orbit)}
        return pb2.TleToOrbitRes(**result)

    def ToCorridor(self, request, context):
        corridor = ''
        try:
            c.GenerateCorridorImage(request.tle_data.line1, request.tle_data.line2)
            corridor = '<img src="/static/test.png">'
        except Exception as e:
            print('Exception type "%s" in ToCorridor()' % type(e).__name__)
            print(e, flush=True)
        result = {'corridor': corridor}
        return pb2.TleToCorridorRes(**result)


# See https://github.com/grpc/grpc/blob/master/doc/python/server_reflection.md
def enableReflectionAPI(server):
    reflection.enable_server_reflection(_SERVICE_NAMES, server)


# See https://github.com/grpc/grpc/blob/master/examples/python/xds/server.py
def enableHealthChecks(server):
    # Create a health check servicer. We use the non-blocking implementation
    # to avoid thread starvation.
    health_servicer = health.HealthServicer(
        experimental_non_blocking=True,
        experimental_thread_pool=futures.ThreadPoolExecutor(
            max_workers=_THREAD_POOL_SIZE))
    health_pb2_grpc.add_HealthServicer_to_server(health_servicer, server)

    for service in _SERVICE_NAMES:
        health_servicer.set(service, health_pb2.HealthCheckResponse.SERVING)


def serve(opts):
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=_THREAD_POOL_SIZE))
    enableReflectionAPI(server)
    enableHealthChecks(server)

    # Start Dash server to plot orbits.
    orbit_plotter.Start(opts.dash_port)

    pb2_grpc.add_TleServicer_to_server(TleService(), server)

    server.add_insecure_port('[::]:' + opts.server_port)
    server.start()
    print(f'\ngRPC server running on ":{opts.server_port}"')
    server.wait_for_termination()


if __name__ == '__main__':
    serve(inputFlags())
