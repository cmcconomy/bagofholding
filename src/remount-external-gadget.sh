#!/bin/bash

modprobe -r g_mass_storage
modprobe g_mass_storage file=/piusb.bin stall=0 ro=0 removable=1 
