#!/usr/bin/env python3

from pytm import (
    TM,
    Server,
)

tm = TM("Negative Example")

server = Server("Secure Server")
server.allowsClientSideScripting = False
server.controls.disablesiFrames = True
server.controls.implementsCSRFToken = True
server.controls.implementsStrictHTTPValidation = True
server.controls.sanitizesInput = True
server.controls.validatesHeaders = True
server.controls.validatesInput = True

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
