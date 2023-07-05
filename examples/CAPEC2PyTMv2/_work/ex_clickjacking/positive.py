#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Positive Example")

server = Server("Vulnerable Server")
server.allowsClientSideScripting = True
server.controls.disablesiFrames = False
server.controls.implementsCSRFToken = False
server.controls.implementsStrictHTTPValidation = False
server.controls.sanitizesInput = False
server.controls.validatesHeaders = False
server.controls.validatesInput = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
