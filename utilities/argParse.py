import argparse
import sys

def pvtArgParse():
    parser = argparse.ArgumentParser(description='B2G Flash Tool by TWQA')
    parser.add_argument('-v', '--version', help='target build version')
    parser.add_argument('-d', '--device', help='target device codename')
    parser.add_argument('-s', '--serial', help='directs command to device with the given serial number')
    parser.add_argument('-f', '--full_flash', action='store_true', help='flash full image of device')
    parser.add_argument('-g', '--gaia', action='store_true', help='shallow flash gaia into device')
    parser.add_argument('-G', '--gecko', action='store_true', help='shallow flash gaia into device')
    parser.add_argument('--usr', action='store_true', help='specify user build')
    parser.add_argument('--eng', action='store_true', help='specify engineer build')
    parser.add_argument('-b', '--build', help='specify target build YYYYMMDDhhmmss')
    parser.add_argument('-w', help='interaction GUI mode')
    parser.add_argument('-u', '--username', help='LDAP account (will load from .ldap file if exists)')
    parser.add_argument('-p', '--password', help='LDAP password (will load from .ldap file if exists)')
    parser.add_argument('--uninstall_comril', help='uninstall com-ril when shallow flash gecko')
    parser.add_argument('--dl_home', help='specify download forlder')
    options = parser.parse_args(sys.argv[1:])
    return options


if __name__ == "__main__":
    print pvtArgParse()
