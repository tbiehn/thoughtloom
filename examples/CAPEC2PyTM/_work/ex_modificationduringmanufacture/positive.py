#!/usr/bin/env python3

from pytm import (
    TM,
    ExternalEntity,
)

tm = TM("Positive Example")

attacker = ExternalEntity("Attacker")
attacker.hasPhysicalAccess = True

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
