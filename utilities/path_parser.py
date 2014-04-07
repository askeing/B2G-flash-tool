import urllib2
import re


class PathParser(object):

    def get_builds_list_from_url(self, url):
        content = self._open_url(url)
        build_and_time_list = self._parse_build_and_time_from_html(content)
        return self._parse_device_version_and_time_from_list(build_and_time_list)

    def get_available_packages_from_url(self, base_url, build_src):
        html = self._open_url(base_url + build_src + '/latest')
        return self._parse_available_packages(build_src, html)

    def _parse_available_packages(self, build_src, html_content):
        packages_dict = {}
        target_build_src = build_src.replace('-eng', '')
        splited_build_info = target_build_src.split('-', 2)
        device_name = splited_build_info[2]
        # Gecko pattern
        gecko_pattern = re.compile(
            '<a href="b2g-.*?.android-arm.tar.gz">(?P<gecko>b2g-.*?.android-arm.tar.gz)</a>',
            re.DOTALL | re.MULTILINE)
        # Gaia pattern
        gaia_pattern = re.compile(
            '<a href="gaia.zip">(?P<gaia>gaia.zip)</a>',
            re.DOTALL | re.MULTILINE)
        # Images package pattern
        images_pattern = re.compile(
            '<a href="' + device_name + '.zip">(?P<images>' + device_name + '.zip)</a>',
            re.DOTALL | re.MULTILINE)
        gecko = gecko_pattern.findall(html_content)
        gaia = gaia_pattern.findall(html_content)
        images = images_pattern.findall(html_content)
        if len(gecko) == 1:
            packages_dict.update({'gecko': gecko[0]})
        if len(gaia) == 1:
            packages_dict.update({'gaia': gaia[0]})
        if len(images) == 1:
            packages_dict.update({'images': images[0]})
        return packages_dict

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
            # If the build name ends with '-eng', then it is Engineer build.
            build_src = build_and_time[0]
            engineer_build = build_src.endswith('-eng')
            # Remove '-eng', then split string by '-'
            target_build_src = build_src.replace('-eng', '')
            splited_build_info = target_build_src.split('-', 2)
            device_name = splited_build_info[2]
            branch_name = splited_build_info[1]
            src_name = build_and_time[0]
            build = 'Engineer' if engineer_build else 'User'
            last_modify_time = build_and_time[1]
            build_item = {build: {'src': src_name, 'last_modify_time': last_modify_time}}

            if root_dict.get(device_name) == None:
                root_dict[device_name] = {}
            if root_dict[device_name].get(branch_name) == None:
                root_dict[device_name][branch_name] = {}
            root_dict[device_name][branch_name].update(build_item)
        return root_dict
