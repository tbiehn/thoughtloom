#!/usr/bin/env python3

from pytm import (
    TM,
    Process
)

tm = TM("Positive Example")

target_process = Process("Target Process")
target_process.codeType="C"
target_process.implementsCommunicationProtocol = True
target_process.tracksExecutionFlow = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
