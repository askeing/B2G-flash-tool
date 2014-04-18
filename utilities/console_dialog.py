import os
import sys
import string
import getpass


class ConsoleDialog(object):

    _SYMBOL_CHAR = '#'
    _NAME = 'NAME'
    _TYPE = 'TYPE'
    _COMMAND_TYPE = 'COMMAND'
    _ITEM_TYPE = 'ITEM'
    _QUIT_CMD_INDEX = 'q'
    _QUIT_CMD_NAME = 'QUIT'
    _YES_CMD_INDEX = 'y'
    _NO_CMD_INDEX ='n'

    def __init__(self):
        try:
            self.console_rows, self.console_columns = ConsoleDialog.get_terminal_size()
        except:
            self.console_rows = 23
            self.console_columns = 80

    def menu(self, title, description, items_list, dialog_width=80, alternative_cmds_dict={}):
        '''
        Create the menu dialog.
        The index of items_list will be numbers.
        The index of alternative_cmds_dict should be lowercase characters. ex: {'b': 'BACK TO PREV STEP', 'h': 'HELP'}
        '''
        # print title
        self._print_title(title)
        # create items dict
        items_dict = self._create_items_dict(items_list, alternative_cmds_dict)
        self._print_items_dict(items_dict)
        # get response from raw input
        response = ''
        while response not in items_dict.keys() and not response == self._QUIT_CMD_INDEX:
            response = self._get_dialog_input_with_desc(description).lower()
        # return selection
        return {'SELECT': response, 'ITEMS': items_dict}

    def input_box(self, title, description, password=False, dialog_width=80):
        # print title
        self._print_title(title)
        if password:
            response = getpass.getpass('> ' + description + ': ')
        else:
            response = self._get_dialog_input_with_desc(description)
        return response

    def msg_box(self, title, description, press_enter_to_next=False, dialog_width=80):
        # print title
        self._print_title(title)
        print '> ' + description
        self._print_horizontal_lines()
        print ''
        if press_enter_to_next:
            raw_input("Press Enter to continue...")

    def yes_no(self, title, description, default_value='', dialog_width=80):
        default = default_value.lower()
        if default_value not in [self._YES_CMD_INDEX, self._NO_CMD_INDEX]:
            default = ''
        question_mark = ' (y/n) '
        if default_value == self._YES_CMD_INDEX:
            question_mark = ' (Y/n) '
        elif default_value == self._NO_CMD_INDEX:
            question_mark = ' (y/N) '
        # print title
        self._print_title(title)
        # get response from raw input
        response = ''
        while response not in [self._YES_CMD_INDEX, self._NO_CMD_INDEX]:
            response = self._get_dialog_input_with_desc(description + question_mark).lower()
            if len(default_value) > 0 and response not in [self._YES_CMD_INDEX, self._NO_CMD_INDEX]:
                response = default_value
        answer = True if response == self._YES_CMD_INDEX else False
        return answer

    def _create_items_dict(self, items_list, alternative_cmds_dict={}):
        items_dict = {self._QUIT_CMD_INDEX: {self._NAME: self._QUIT_CMD_NAME, self._TYPE: self._COMMAND_TYPE}}
        # create the items dict.
        index = 1
        for item in items_list:
            items_dict[str(index)] = {self._NAME: item, self._TYPE: self._ITEM_TYPE}
            index = index + 1
        # create the alternative options dict.
        if len(alternative_cmds_dict) > 0:
            temp_alternative_options_dict = alternative_cmds_dict.copy()
            option_index = 0
            # if the option key still not be used, then add it into result dict.
            for option_key, option_value in temp_alternative_options_dict.items():
                if option_key not in items_dict.keys():
                    items_dict[str(option_key)] = {self._NAME: option_value, self._TYPE: self._COMMAND_TYPE}
                    del temp_alternative_options_dict[option_key]
            # if the option key be used, then add it with no used char.
            for option_key, option_value in temp_alternative_options_dict.items():
                chars = string.lowercase.replace('q', '')
                while chars[option_index] in items_dict.keys():
                    option_index = option_index + 1
                items_dict[chars[option_index]] = {self._NAME: option_value, self._TYPE: self._COMMAND_TYPE}
        return items_dict

    def _print_items_dict(self, items_dict):
        for index in sorted(items_dict):
            if items_dict[index][self._TYPE] == self._ITEM_TYPE:
                print 'ITEM',
            else:
                print 'CMD ',
            print index + ')', items_dict[index][self._NAME]
        self._print_horizontal_lines()

    def _print_title(self, title):
        print ''
        self._update_terminal_size()
        self._print_horizontal_lines()
        print self._SYMBOL_CHAR, title
        self._print_horizontal_lines()

    def _get_dialog_input_with_desc(self, description):
        response = raw_input('> ' + description + ': ')
        return response

    def _print_horizontal_lines(self):
        for i in xrange(0, int(self.console_columns)):
            sys.stdout.write(self._SYMBOL_CHAR)
            sys.stdout.flush()

    def _update_terminal_size(self):
        self.console_rows, self.console_columns = ConsoleDialog.get_terminal_size()

    @staticmethod
    def get_terminal_size():
        '''
        return the rows and columns of terminal.
        Reference: http://stackoverflow.com/questions/566746/how-to-get-console-window-width-in-python
        '''
        return os.popen('stty size', 'r').read().split()
