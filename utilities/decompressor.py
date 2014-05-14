import os
import types
import zipfile
import tarfile
from logger import Logger


class Decompressor(object):

    def __init__(self):
        self.logger = Logger()

    def unzip(self, source_file, dest_folder, status_callback=None):
        try:
            self.logger.log('Unzip ' + source_file + ' to ' + dest_folder, status_callback=status_callback)
            zip_file = zipfile.ZipFile(source_file)
            zip_file.extractall(dest_folder)
            zip_file.close()
            self.logger.log('Unzip done', status_callback=status_callback)
        except Exception as e:
            self.logger.log('Unzip Error ' + source_file, status_callback=status_callback, level=Logger._LEVEL_WARNING)

    def untar(self, source_file, dest_folder, status_callback=None):
        try:
            self.logger.log('Untar' + source_file + 'to' + dest_folder, status_callback=status_callback)
            tar_file = tarfile.open(source_file)
            tar_file.extractall(dest_folder)
            tar_file.close()
            self.logger.log('Untar done', status_callback=status_callback)
        except Exception as e:
            self.logger.log('Untar Error ' + source_file, status_callback=status_callback, level=Logger._LEVEL_WARNING)

    def ensure_folder(self, folder):
        if not os.path.isdir(folder):
            os.makedirs(folder)
