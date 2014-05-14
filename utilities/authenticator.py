import types
import urllib2
from logger import Logger


class Authenticator(object):

    _is_authenticated = False

    def __init__(self):
        self.logger = Logger()

    def authenticate(self, top_level_url, username, password, status_callback=None):
        try:
            self.logger.log('Log in ' + username + ' ...', status_callback=status_callback)
            _authn_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
            _authn_manager.add_password(None, top_level_url, username, password)
            _handler = urllib2.HTTPBasicAuthHandler(_authn_manager)
            _opener = urllib2.build_opener(_handler)
            _opener.open(top_level_url)
            urllib2.install_opener(_opener)
            self._is_authenticated = True
        except urllib2.HTTPError as e:
            self.logger.log('Authenticate Error: ' + str(e.code) + ' ' + e.msg, status_callback=status_callback, level=Logger._LEVEL_WARNING)
            self._is_authenticated = False

    @property
    def is_authenticated(self):
        return self._is_authenticated
