from tletools import TLE

TLE_STRING = """
ISS (ZARYA)
1 25544U 98067A   98324.28472222 -.00003657  11563-4  00000+0 0  9996
2 25544 051.5908 168.3788 0125362 086.4185 359.7454 16.05064833    05
"""

def Decode(tle_parts):
    return str(TLE.from_lines(*tle_parts))

def ToOrbit(tle_parts):
    return str(TLE.from_lines(*tle_parts).to_orbit())
