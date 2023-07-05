#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Negative Example")

web = Server("Web Server")
web.controls.hasAccessControl = True
web.controls.validatesInput = True

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
