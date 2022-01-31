from tletools import TLE

def toList(tle_data):
    return [tle_data.name, tle_data.line1, tle_data.line2]

def Decode(tle_data):
    return TLE.from_lines(*toList(tle_data))

def ToOrbit(tle_data):
    return TLE.from_lines(*toList(tle_data)).to_orbit()
