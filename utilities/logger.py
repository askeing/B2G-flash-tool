import types


class Logger(object):

    def log(self, message, status_callback=None):
        print '###', message
        if isinstance(status_callback, types.FunctionType):
            status_callback(message)
