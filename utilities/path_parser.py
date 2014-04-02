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
        root_dict = {}
        for build_and_time in build_and_time_list:
            splited_build_info = build_and_time[0].split('-')
            device_name = splited_build_info[2]
            branch_name = splited_build_info[1]
            if len(splited_build_info) == 4:
                engineer_build = True
            else:
                engineer_build = False
            src_name = build_and_time[0]
            last_modify_time = build_and_time[1]
            build = 'Engineer' if engineer_build else 'User'
            build_item = {build: {'src': src_name, 'last_modify_time': last_modify_time}}

            if root_dict.get(device_name) == None:
                root_dict[device_name] = {}
            if root_dict[device_name].get(branch_name) == None:
                root_dict[device_name][branch_name] = {}
            root_dict[device_name][branch_name].update(build_item)
        return root_dict
