from tletools import TLE

def Decode(tle_parts):
    return str(TLE.from_lines(*tle_parts))

def ToOrbit(tle_parts):
    return str(TLE.from_lines(*tle_parts).to_orbit())
