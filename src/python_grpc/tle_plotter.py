from threading import Thread

import dash
from dash import dcc
from dash import html
from tletools import TLE

TLE_STRING = """
ISS (ZARYA)
1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996
2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05
"""


def PlotOrbit(dash_port):
    tle_lines = TLE_STRING.strip().splitlines()
    figure = TLE.from_lines(*tle_lines).to_orbit().plot(
        use_3d=True, interactive=True)
    app = dash.Dash()
    app.layout = html.Div([
        dcc.Graph(figure=figure)
    ])

    thread = Thread(target=app.run_server,
                    kwargs={'debug': True,
                            'port': dash_port,
                            # Required so the server is accessible when running in Docker.
                            # See https://stackoverflow.com/questions/44045451/cant-access-flask-app-which-is-inside-docker-container
                            'host': '0.0.0.0',
                            # Set 'use_reloader' to False to enable running in a new thread.
                            # see https://stackoverflow.com/questions/31264826/start-a-flask-application-in-separate-thread
                            'use_reloader': False})
    thread.start()
