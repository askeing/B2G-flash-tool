import urllib2


class Authenticator(object):

    _is_authenticated = False

    def authenticate(self, top_level_url, username, password):
        try:
             _authn_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
             _authn_manager.add_password(None, top_level_url, username, password)
             _handler = urllib2.HTTPBasicAuthHandler(_authn_manager)
             _opener = urllib2.build_opener(_handler)
             _opener.open(top_level_url)
             urllib2.install_opener(_opener)
             self._is_authenticated = True
        except urllib2.HTTPError as e:
            print '### Authenticate Error:', e.code, e.msg
            self._is_authenticated = False

    @property
    def is_authenticated(self):
        return self._is_authenticated
