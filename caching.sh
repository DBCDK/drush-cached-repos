#!/bin/bash

cat dbcore.make | sed -e "/\.git[\"']* *$/ ! d; s/.*= *[\"']*\([^'\"]*\)[\"']* *$/\1/" -e "s/:\/\//-/; y/@:/-\//"


