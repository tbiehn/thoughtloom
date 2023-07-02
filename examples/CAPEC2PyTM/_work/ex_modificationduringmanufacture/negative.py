#!/usr/bin/env python3

from pytm import (
    TM,
    ExternalEntity,
)

tm = TM("Negative Example")

attacker = ExternalEntity("Attacker")
attacker.hasPhysicalAccess = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
