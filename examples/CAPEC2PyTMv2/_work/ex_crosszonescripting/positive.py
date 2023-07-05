#!/usr/bin/env python3

from pytm import TM, Server, Dataflow, Actor, Boundary

tm = TM("TM")

internet = Boundary("Internet")

user = Actor("User")
user.inBoundary = internet

web = Server("Web Server")
web.allowsClientSideScripting = True
web.controls.sanitizesInput = False
web.controls.validatesInput = False
web.controls.encodesOutput = False

data_in_text = Dataflow(user, web, "User enters data (*)")
data_in_text.protocol = "HTTP"
data_in_text.dstPort = 80

tm.threatsFile = "./threats.json"
tm.process()
