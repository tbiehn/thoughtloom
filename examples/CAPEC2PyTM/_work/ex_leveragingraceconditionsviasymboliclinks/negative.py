#!/usr/bin/env python3

from pytm import TM, Server, Dataflow, Boundary, Actor, Process

tm = TM("Symlink Attack")

target = Boundary("Target System")

attacker = Actor("Attacker")

secure_process = Process("Secure Process")
secure_process.inBoundary = target
secure_process.usesSymlinks = True
secure_process.controls.validatesInput = True

attack = Dataflow(attacker, secure_process, "Symlink Attack")

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
