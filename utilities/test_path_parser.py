import unittest
from path_parser import PathParser


class testPathParser(unittest.TestCase):

    def setUp(self):
        self.test_html = """
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
        self.expect_result = {'nexus': {'central': {'User': {'src': 'mozilla-central-nexus-4-eng', 'last_modify_time': '03-Apr-2014 00:56'}}},
                              'hamachi': {'aurora': {'Engineer': {'src': 'mozilla-aurora-hamachi-eng', 'last_modify_time': '03-Apr-2014 00:44'}}}}

    def test_path_parser(self):
        path_parser = PathParser()
        result = path_parser._parse_device_version_and_time_from_list(path_parser._parse_build_and_time_from_html(self.test_html))
        self.assertEqual(result, self.expect_result)

if __name__ == '__main__':
    unittest.main()
