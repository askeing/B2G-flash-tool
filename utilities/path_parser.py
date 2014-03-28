import urllib2
import re


class PathParser(object):

    def get_builds_list_from_url(self, url):
        content = self._open_url(url)
        build_and_time_list = self._parse_build_and_time_from_html(content)
        return self._parse_device_version_and_time_from_list(build_and_time_list)

    def _open_url(self, url):
        response = urllib2.urlopen(url)
        html = response.read()
        return html

    def _parse_build_and_time_from_html(self, html_content):
        build_and_time_pattern = re.compile(
            '<a href="mozilla-.*?-.*?/">(?P<build>mozilla-.*?-.*?)/</a></td><td align="right">(?P<time>.*?)\s*</td>',
            re.DOTALL | re.MULTILINE)
        build_and_time_list = build_and_time_pattern.findall(html_content)
        return build_and_time_list

    def _parse_device_version_and_time_from_list(self, build_and_time_list):
        device_build_version_and_time_list = []
        for build_and_time in build_and_time_list:
            splited_build_info = build_and_time[0].split('-')
            item = {}
            item['device'] = splited_build_info[2]
            item['branch'] = splited_build_info[1]
            if len(splited_build_info) == 4:
                item['engineer'] = True
            else:
                item['engineer'] = False
            item['src'] = build_and_time[0]
            item['time'] = build_and_time[1]
            device_build_version_and_time_list.append(item)
        return device_build_version_and_time_list
