#!/usr/bin/env python3

from pytm import TM, Server, Dataflow, Actor, Boundary

tm = TM("TM")

internet = Boundary("Internet")

user = Actor("User")
user.inBoundary = internet

web = Server("Web Server")
web.allowsClientSideScripting = False
web.controls.sanitizesInput = True
web.controls.validatesInput = True
web.controls.encodesOutput = True

data_in_text = Dataflow(user, web, "User enters data (*)")
data_in_text.protocol = "HTTP"
data_in_text.dstPort = 80

tm.threatsFile = "./threats.json"
tm.process()
