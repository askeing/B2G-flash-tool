# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os
import urllib2
import console_utilities
from logger import Logger


class Downloader(object):

    def __init__(self):
        self.logger = Logger()

    def download(self, source_url, dest_folder, status_callback=None, progress_callback=None):
        try:
            console_utilities.hide_cursor()
            f = urllib2.urlopen(source_url)
            self.logger.log('Downloading ' + source_url, status_callback=status_callback)
            self.ensure_folder(dest_folder)
            filename_with_path = os.path.join(dest_folder, os.path.basename(source_url))
            with open(filename_with_path, "wb") as local_file:
                total_size = int(f.info().getheader('Content-Length').strip())
                pc = 0
                chunk_size = 8192
                while 1:
                    chunk = f.read(chunk_size)
                    pc += len(chunk)
                    if not chunk:
                        break
                    if progress_callback:
                        progress_callback(current_byte=pc, total_size=total_size)
                    local_file.write(chunk)
            self.logger.log('Download to ' + filename_with_path, status_callback=status_callback)
            console_utilities.show_cursor()
            return filename_with_path
        except urllib2.HTTPError as e:
            self.logger.log('HTTP Error: ' + str(e.code) + ' ' + e.msg + ' of ' + source_url, status_callback=status_callback, level=Logger._LEVEL_WARNING)
        except urllib2.URLError as e:
            self.logger.log('URL Error: ' + str(e.code) + ' ' + e.msg + ' of ' + source_url, status_callback=status_callback, level=Logger._LEVEL_WARNING)

    def ensure_folder(self, folder):
        if not os.path.isdir(folder):
            os.makedirs(folder)
