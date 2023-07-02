#!/usr/bin/env python3

from pytm import (
    TM,
    ExternalEntity,
)

tm = TM("Negative Example")

maliciousActor = ExternalEntity("Malicious Actor")
maliciousActor.hasPhysicalAccess = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
