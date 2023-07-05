#!/usr/bin/env python3

from pytm import (
    TM,
    Process,
    Lambda,
)

tm = TM("Positive Example")

proc = Process("A process")
proc.codeType="C"
proc.implementsAPI = True
proc.controls.validatesInput = False
proc.controls.sanitizesInput = True

my_lambda = Lambda("AWS Lambda")
my_lambda.implementsAPI = True
my_lambda.controls.validatesInput = False
my_lambda.controls.sanitizesInput = False

if __name__ == "__main__":
    tm.threatsFile = "./threats.json"
    tm.process()
