import urllib2


class Authnticator(object):

    def __init__(self, top_level_url, username, password):
        _authn_manager = urllib2.HTTPPasswordMgrWithDefaultRealm()
        _authn_manager.add_password(None, top_level_url, username, password)
        _handler = urllib2.HTTPBasicAuthHandler(_authn_manager)
        _opener = urllib2.build_opener(_handler)
        _opener.open(top_level_url)
        urllib2.install_opener(_opener)
