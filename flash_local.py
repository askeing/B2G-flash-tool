#!/usr/bin/env python

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os
from sys import platform as _platform
from Tkinter import Tk
from tkFileDialog import askopenfilename
from tkMessageBox import askquestion
from tkMessageBox import askyesno


def main():
    window = Tk()
    window.option_add('*Dialog.msg.wrapLength', '10i')
    window.withdraw()

    ret = askyesno('Flash Local', 'It will shallow flash gaia/gecko from local file system.', icon='info')
    if ret:
        pass
    else:
        quit()

    is_flash_gaia = False
    GAIA_FILEOPENOPTIONS = {'title': 'Select the Gaia package (gaia.zip)', 'defaultextension': '.zip', 'filetypes': [('Zip file', '*.zip'), ('All files', '*.*')]}
    gaia_filename = askopenfilename(**GAIA_FILEOPENOPTIONS)
    if gaia_filename:
        is_flash_gaia = True

    is_flash_gecko = False
    GECKO_FILEOPENOPTIONS = {'title': 'Select the Gecko package (b2g-xxx.android-arm.tar.gz)', 'defaultextension': '.tar.gz', 'filetypes': [('Gzip file', '*.tar.gz'), ('All files', '*.*')]}
    gecko_filename = askopenfilename(**GECKO_FILEOPENOPTIONS)
    if gecko_filename:
        is_flash_gecko = True

    if not is_flash_gaia and not is_flash_gecko:
        quit()

    comfirm_message = 'Are You Sure?\n'
    if is_flash_gaia:
        comfirm_message = comfirm_message + '\nGaia:\n%s\n' % gaia_filename
    if is_flash_gecko:
        comfirm_message = comfirm_message + '\nGecko:\n%s\n' % gecko_filename

    ret = askyesno('Comfirm', comfirm_message, icon='warning')
    if ret:
        do_flash(is_flash_gaia, gaia_filename, is_flash_gecko, gecko_filename)
    else:
        quit()


def quit():
    print "Bye"
    exit(0)


def do_flash(is_flash_gaia, gaia_filename, is_flash_gecko, gecko_filename, keep_profile=False):
    cmd = './shallow_flash.sh -y'
    sp = ''
    if _platform == 'darwin':
        sp = ' '
    if is_flash_gaia:
        cmd = cmd + ' -g' + sp + gaia_filename
    if is_flash_gecko:
        cmd = cmd + ' -G' + sp + gecko_filename
    if keep_profile:
        cmd = cmd + ' --keep_profile'
    print('run command: ' + cmd)
    os.system(cmd)

if __name__ == '__main__':
    main()
