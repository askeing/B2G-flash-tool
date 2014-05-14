import os
import types
import urllib2
from logger import Logger


class Downloader(object):

    def __init__(self):
        self.logger = Logger()

    def download(self, source_url, dest_folder, status_callback=None):
        try:
            f = urllib2.urlopen(source_url)
            self.logger.log('Downloading ' + source_url, status_callback=status_callback)
            self.ensure_folder(dest_folder)
            filename_with_path = os.path.join(dest_folder, os.path.basename(source_url))
            with open(filename_with_path, "wb") as local_file:
                local_file.write(f.read())
            self.logger.log('Download to ' + filename_with_path, status_callback=status_callback)
            return filename_with_path
        except urllib2.HTTPError as e:
            self.logger.log('HTTP Error: ' + str(e.code) + ' ' + e.msg + ' of ' + source_url, status_callback=status_callback, level=Logger._LEVEL_WARNING)
        except urllib2.URLError as e:
            self.logger.log('URL Error: ' + str(e.code) + ' ' + e.msg + ' of ' + source_url, status_callback=status_callback, level=Logger._LEVEL_WARNING)

    def ensure_folder(self, folder):
        if not os.path.isdir(folder):
            os.makedirs(folder)
