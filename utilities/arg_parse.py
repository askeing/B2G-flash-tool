import argparse
import sys
import textwrap
from argparse import RawTextHelpFormatter


class Parser(object):

    @staticmethod
    def pvtArgParse(input):
        parser = argparse.ArgumentParser(description='B2G Flash Tool by TWQA',
            formatter_class=RawTextHelpFormatter,
            epilog=textwrap.dedent('''\
            example:
              $ ./flash_pvt.py -d flame -v central --eng -g -G
              $ ./flash_pvt.py -d hamachi -v b2g30_v1_4 -b 20140718000231 --usr -g -G
            '''))
        parser.add_argument('-v', '--version', help='target build version')
        parser.add_argument('-d', '--device', help='target device codename')
        parser.add_argument('-s', '--serial', help='directs command to device with the given serial number')
        parser.add_argument('-f', '--full_flash', action='store_true', help='flash full image of device')
        parser.add_argument('-g', '--gaia', action='store_true', help='shallow flash gaia into device')
        parser.add_argument('-G', '--gecko', action='store_true', help='shallow flash gaia into device')
        parser.add_argument('--usr', action='store_true', help='specify user build')
        parser.add_argument('--eng', action='store_true', help='specify engineer build')
        parser.add_argument('-b', '--build_id', help='specify target build YYYYMMDDhhmmss')
        parser.add_argument('-w', '--window', action='store_true', help='interaction GUI mode')
        parser.add_argument('-u', '--username', help='LDAP account (will load from .flash_pvt file if exists)')
        parser.add_argument('-p', '--password', help='LDAP password (will load from .flash_pvt file if exists)')
        parser.add_argument('--dl_home', help='specify download forlder')
        parser.add_argument('--keep_profile', action='store_true', help='keep the user profile (BETA)')
        options = parser.parse_args(input)
        return options

if __name__ == "__main__":
    if len(sys.argv) > 1:
        print Parser.pvtArgParse(sys.argv[1:])
    else:
        testSample = ["-v", "v2.0", "-d=buri", "-g", "-G"]
        print Parser.pvtArgParse(testSample)
