import math
import cartopy.crs as ccrs
import matplotlib.pyplot as plt
import orekit
from orekit.pyhelpers import setup_orekit_curdir
from org.orekit.utils import Constants
from org.orekit.propagation.analytical.tle import TLE
from org.orekit.propagation.analytical.tle import TLEPropagator
from org.hipparchus.geometry.euclidean.threed import Line
from org.hipparchus.geometry.euclidean.threed import Vector3D
from org.orekit.bodies import OneAxisEllipsoid
from org.orekit.frames import FramesFactory
from org.orekit.utils import IERSConventions
from org.orekit.propagation.sampling import PythonOrekitFixedStepHandler

DURATION = 1.0 * 60 * 180
STEP = 10.0
ANGULAR_OFFSET = 35 # Sensor half width


# Example from
# https://gitlab.orekit.org/orekit-labs/python-wrapper/-/blob/master/examples/Track_Corridor.ipynb
class CorridorHandler(PythonOrekitFixedStepHandler):
    def __init__(self, angle):
        # Set up Earth model.
        self.earth = OneAxisEllipsoid(Constants.WGS84_EARTH_EQUATORIAL_RADIUS,
                                      Constants.WGS84_EARTH_FLATTENING,
                                      FramesFactory.getITRF(IERSConventions.IERS_2010, False))

        # Set up position offsets, using Earth radius as an arbitrary distance.
        self.deltaR = Constants.WGS84_EARTH_EQUATORIAL_RADIUS * math.cos(math.radians(angle))
        self.deltaC = Constants.WGS84_EARTH_EQUATORIAL_RADIUS * math.sin(math.radians(angle))

        # Prepare an empty corridor.
        self.dates = []
        self.lefts = []
        self.centers = []
        self.rights = []

        super(CorridorHandler, self).__init__()

    # Methods init and finish need to be present to match the Java interface.
    def init(self, s0, t, step):
        pass

    def finish(self, finalState):
        pass

    def handleStep(self, currentState):
        # Compute sub-satellite track.
        date = currentState.getDate()
        pvInert = currentState.getPVCoordinates()
        t = currentState.getFrame().getTransformTo(self.earth.getBodyFrame(), date)
        p = t.transformPosition(pvInert.getPosition())
        v = t.transformVector(pvInert.getVelocity())
        center = self.earth.transform(p, self.earth.getBodyFrame(), date)

        # Compute left and right corridor points.
        nadir = p.normalize().negate()
        crossTrack = p.crossProduct(v).normalize()
        leftLine = Line(p, Vector3D(1.0, p, self.deltaR, nadir, self.deltaC, crossTrack), 1.0)
        left = self.earth.getIntersectionPoint(leftLine, p, self.earth.getBodyFrame(), date)
        rightLine = Line(p, Vector3D(1.0, p, self.deltaR, nadir, -self.deltaC, crossTrack), 1.0)
        right = self.earth.getIntersectionPoint(rightLine, p, self.earth.getBodyFrame(), date)

        # Add corridor points.
        self.dates.append(date)
        self.lefts.append(left)
        self.centers.append(center)
        self.rights.append(right)


class Generator():
    def __init__(self):
        self.vm = orekit.initVM()
        setup_orekit_curdir()
        self.PrintVersions()

    def PrintVersions(self):
        print('Java version:', self.vm.java_version)
        print('Orekit version:', orekit.VERSION)

    def GenerateCorridorImage(self, tle_line1, tle_line2):
        self.vm.attachCurrentThread()
        tle = TLE(tle_line1, tle_line2)
        propagator = TLEPropagator.selectExtrapolator(tle)
        handler = CorridorHandler(ANGULAR_OFFSET)
        propagator.getMultiplexer().add(STEP, handler)

        start = tle.getDate()
        propagator.propagate(start, start.shiftedBy(DURATION))

        def geoline(geopoints):
            lon = [math.degrees(x.getLongitude()) for x in geopoints]
            lat = [math.degrees(x.getLatitude()) for x in geopoints]
            return lon, lat

        # Front view.
        plt.figure(figsize=(14, 14))
        ax = plt.axes(projection=ccrs.PlateCarree())
        ax.coastlines()

        lon, lat = geoline(handler.centers)
        ax.plot(
            lon, lat, transform=ccrs.Geodetic(), alpha=0.6, color='green', zorder=3)

        lon, lat = geoline(handler.lefts)
        ax.plot(
            lon, lat, transform=ccrs.Geodetic(), alpha=0.6, color='blue', zorder=3)

        lon, lat = geoline(handler.rights)
        ax.plot(
            lon, lat, transform=ccrs.Geodetic(), alpha=0.6, color='blue', zorder=3)

        plt.savefig('src/ui/static/test.png', bbox_inches='tight')
