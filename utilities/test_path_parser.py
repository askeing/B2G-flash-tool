import unittest
from path_parser import PathParser


class testPathParser(unittest.TestCase):

    def setUp(self):
        # For test_parser_root()
        self.test_html_root = """
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
        <html>
         <head>
           <title>Index of /pvt/mozilla.org/b2gotoro/nightly</title>
         </head>
         <body>
         <h1>Index of /pvt/mozilla.org/b2gotoro/nightly</h1>
         <table><tr><th><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr><tr><th colspan="5"><hr></th></tr>
         <tr><td valign="top"><img src="/icons/back.gif" alt="[DIR]"></td><td><a href="/pvt/mozilla.org/b2gotoro/">Parent Directory</a></td><td>&nbsp;</td><td align="right">  - </td><td>&nbsp;</td></tr>
         <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="mozilla-aurora-hamachi-eng/">mozilla-aurora-hamachi-eng/</a></td><td align="right">03-Apr-2014 00:44  </td><td align="right">  - </td><td>&nbsp;</td></tr>
         <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="mozilla-central-nexus-4-eng/">mozilla-central-nexus-4-eng/</a></td><td align="right">03-Apr-2014 00:56  </td><td align="right">  - </td><td>&nbsp;</td></tr>
         <tr><th colspan="5"><hr></th></tr>
         </table>
         </body>
        </html>
        """
        self.expect_result_root = {'nexus-4': {'central': {'Engineer': {'src': 'mozilla-central-nexus-4-eng', 'last_modify_time': '03-Apr-2014 00:56'}}},
                              'hamachi': {'aurora': {'Engineer': {'src': 'mozilla-aurora-hamachi-eng', 'last_modify_time': '03-Apr-2014 00:44'}}}}
        # For test_parser_packages_gaia_gecko()
        self.test_html_packages_src_gaia_gecko = 'mozilla-central-hamachi-eng'
        self.test_html_packages_gaia_gecko = """
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
        <html>
         <head>
          <title>Index of /pvt/mozilla.org/b2gotoro/nightly/mozilla-central-hamachi-eng/latest</title>
         </head>
         <body>
        <h1>Index of /pvt/mozilla.org/b2gotoro/nightly/mozilla-central-hamachi-eng/latest</h1>
        <table><tr><th><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr><tr><th colspan="5"><hr></th></tr>
        <tr><td valign="top"><img src="/icons/back.gif" alt="[DIR]"></td><td><a href="/pvt/mozilla.org/b2gotoro/nightly/mozilla-central-hamachi-eng/">Parent Directory</a></td><td>&nbsp;</td><td align="right">  - </td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="b2g-31.0a1.en-US.android-arm.crashreporter-symbols.zip">b2g-31.0a1.en-US.android-arm.crashreporter-symbols.zip</a></td><td align="right">07-Apr-2014 00:43  </td><td align="right"> 32M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="b2g-31.0a1.en-US.android-arm.tar.gz">b2g-31.0a1.en-US.android-arm.tar.gz</a></td><td align="right">07-Apr-2014 00:43  </td><td align="right"> 21M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/unknown.gif" alt="[   ]"></td><td><a href="build.prop">build.prop</a></td><td align="right">07-Apr-2014 00:43  </td><td align="right">5.9K</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="gaia.zip">gaia.zip</a></td><td align="right">07-Apr-2014 00:43  </td><td align="right"> 51M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="logs/">logs/</a></td><td align="right">07-Apr-2014 00:43  </td><td align="right">  - </td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="sources.xml">sources.xml</a></td><td align="right">07-Apr-2014 00:43  </td><td align="right"> 12K</td><td>&nbsp;</td></tr>
        <tr><th colspan="5"><hr></th></tr>
        </table>
        </body></html>
        """
        self.expect_result_packages_gaia_gecko = {'gaia': 'gaia.zip', 'gecko': 'b2g-31.0a1.en-US.android-arm.tar.gz'}
        # For test_parser_packages_all()
        self.test_html_packages_src_all = 'mozilla-central-nexus-4-eng'
        self.test_html_packages_all = """
        <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
        <html>
         <head>
          <title>Index of /pvt/mozilla.org/b2gotoro/nightly/mozilla-central-nexus-4-eng/latest</title>
         </head>
         <body>
        <h1>Index of /pvt/mozilla.org/b2gotoro/nightly/mozilla-central-nexus-4-eng/latest</h1>
        <table><tr><th><img src="/icons/blank.gif" alt="[ICO]"></th><th><a href="?C=N;O=D">Name</a></th><th><a href="?C=M;O=A">Last modified</a></th><th><a href="?C=S;O=A">Size</a></th><th><a href="?C=D;O=A">Description</a></th></tr><tr><th colspan="5"><hr></th></tr>
        <tr><td valign="top"><img src="/icons/back.gif" alt="[DIR]"></td><td><a href="/pvt/mozilla.org/b2gotoro/nightly/mozilla-central-nexus-4-eng/">Parent Directory</a></td><td>&nbsp;</td><td align="right">  - </td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="b2g-31.0a1.en-US.android-arm.crashreporter-symbols.zip">b2g-31.0a1.en-US.android-arm.crashreporter-symbols.zip</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right"> 32M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="b2g-31.0a1.en-US.android-arm.tar.gz">b2g-31.0a1.en-US.android-arm.tar.gz</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right"> 20M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/unknown.gif" alt="[   ]"></td><td><a href="build.prop">build.prop</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right">2.4K</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="gaia.zip">gaia.zip</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right"> 58M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/folder.gif" alt="[DIR]"></td><td><a href="logs/">logs/</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right">  - </td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/compressed.gif" alt="[   ]"></td><td><a href="nexus-4.zip">nexus-4.zip</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right">141M</td><td>&nbsp;</td></tr>
        <tr><td valign="top"><img src="/icons/text.gif" alt="[TXT]"></td><td><a href="sources.xml">sources.xml</a></td><td align="right">07-Apr-2014 00:40  </td><td align="right"> 17K</td><td>&nbsp;</td></tr>
        <tr><th colspan="5"><hr></th></tr>
        </table>
        </body></html>
        """
        self.expect_result_packages_all = {'images': 'nexus-4.zip', 'gaia': 'gaia.zip', 'gecko': 'b2g-31.0a1.en-US.android-arm.tar.gz'}

    def test_parser_root(self):
        path_parser = PathParser()
        result = path_parser._parse_device_version_and_time_from_list(path_parser._parse_build_and_time_from_html(self.test_html_root))
        self.assertEqual(result, self.expect_result_root)

    def test_parser_packages_gaia_gecko(self):
        path_parser = PathParser()
        result = path_parser._parse_available_packages(self.test_html_packages_src_gaia_gecko, self.test_html_packages_gaia_gecko)
        self.assertEqual(result, self.expect_result_packages_gaia_gecko)

    def test_parser_packages_all(self):
        path_parser = PathParser()
        result = path_parser._parse_available_packages(self.test_html_packages_src_all, self.test_html_packages_all)
        self.assertEqual(result, self.expect_result_packages_all)

    def test_verify_build_id(self):
        path_parser = PathParser()
        self.assertTrue(path_parser._verify_build_id('20140408160201'))
        self.assertTrue(path_parser._verify_build_id('2014-04-08-16-02-01'))
        self.assertFalse(path_parser._verify_build_id('2014-04-08-16-02-01-0000'))
        self.assertFalse(path_parser._verify_build_id('This is not build id'))

    def test_get_path_of_build_id(self):
        path_parser = PathParser()
        self.assertEqual('/2014/04/2014-04-08-16-02-01/', path_parser._get_path_of_build_id('2014-04-08-16-02-01'))
        self.assertEqual('/2014/04/2014-04-13-16-02-02/', path_parser._get_path_of_build_id('2014-04-13-16-02-02'))

if __name__ == '__main__':
    unittest.main()
