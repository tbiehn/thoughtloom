#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Positive Example")

web = Server("Web Server")
web.controls.hasAccessControl = False
web.controls.validatesInput = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
