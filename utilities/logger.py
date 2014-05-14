import types


class Logger(object):

    _SYMBOL_CHAR = '###'
    _LEVEL_INFO = 'INFO'
    _LEVEL_WARNING = 'WARNING'
    _LEVEL_DEBUG = 'DEBUG'

    def log(self, message, status_callback=None, level='INFO'):
        print self._SYMBOL_CHAR + ' ' + level + ': ' + message
        if isinstance(status_callback, types.FunctionType) or isinstance(status_callback, types.MethodType):
            status_callback(message)
