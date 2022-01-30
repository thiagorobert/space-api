from tletools import TLE
import corridor_plotter
import orbit_plotter

def Decode(tle_parts):
    return str(TLE.from_lines(*tle_parts))

def ToOrbit(tle_parts):
    orbit = TLE.from_lines(*tle_parts).to_orbit()
    orbitFigure = orbit.plot(use_3d=True, interactive=True)
    try:
        corridor_plotter.GenerateCorridorImage(tle_parts[1], tle_parts[2])
    except Exception as e:
        print('Exception type "%s" from GenerateCorridorImage()' % type(e).__name__)
        print(e)
    orbit_plotter.Plot(orbitFigure)
    return str(orbit)
