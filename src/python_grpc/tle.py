from tletools import TLE
import tle_plotter

def Decode(tle_parts):
    return str(TLE.from_lines(*tle_parts))

def ToOrbit(tle_parts):
    orbit = TLE.from_lines(*tle_parts).to_orbit()
    orbitFigure = orbit.plot(use_3d=True, interactive=True)
    tle_plotter.Plot(orbitFigure)
    return str(orbit)
