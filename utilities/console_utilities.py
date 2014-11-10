# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

import os
import sys


COLOR_BLACK = 'black'
COLOR_BLUE = 'blue'
COLOR_GREEN = 'green'
COLOR_AQUA = 'aqua'
COLOR_RED = 'red'
COLOR_PURPLE = 'purple'
COLOR_YELLOW = 'yellow'
COLOR_WHITE = 'white'
COLOR_GRAY = 'gray'
COLOR_LIGHT_BLUE = 'lightblue'
COLOR_LIGHT_GREEN = 'lightgreen'
COLOR_LIGHT_AQUA = 'lightaqua'
COLOR_LIGHT_RED = 'lightred'
COLOR_LIGHT_PURPLE = 'lightpurple'
COLOR_LIGHT_YELLOW = 'lightyellow'
COLOR_BRIGHT_WHITE = 'brightwhite'


if os.name == 'posix':
    POSIX_COLOR_RESET = '\x1b[0m'
    POSIX_FG_COLOR_TABLE = {COLOR_BLACK: '\x1b[30m',
                            COLOR_BLUE: '\x1b[34m',
                            COLOR_GREEN: '\x1b[32m',
                            COLOR_AQUA: '\x1b[36m',
                            COLOR_RED: '\x1b[31m',
                            COLOR_PURPLE: '\x1b[35m',
                            COLOR_YELLOW: '\x1b[33m',
                            COLOR_WHITE: '\x1b[37m',
                            COLOR_GRAY: '\x1b[1;30m',
                            COLOR_LIGHT_BLUE: '\x1b[1;34m',
                            COLOR_LIGHT_GREEN: '\x1b[1;32m',
                            COLOR_LIGHT_AQUA: '\x1b[1;36m',
                            COLOR_LIGHT_RED: '\x1b[1;31m',
                            COLOR_LIGHT_PURPLE: '\x1b[1;35m',
                            COLOR_LIGHT_YELLOW: '\x1b[1;33m',
                            COLOR_BRIGHT_WHITE: '\x1b[1;37m'
                            }
    POSIX_BG_COLOR_TABLE = {COLOR_BLACK: '\x1b[40m',
                            COLOR_BLUE: '\x1b[44m',
                            COLOR_GREEN: '\x1b[42m',
                            COLOR_AQUA: '\x1b[46m',
                            COLOR_RED: '\x1b[41m',
                            COLOR_PURPLE: '\x1b[45m',
                            COLOR_YELLOW: '\x1b[43m',
                            COLOR_WHITE: '\x1b[47m',
                            COLOR_GRAY: '\x1b[1;40m',
                            COLOR_LIGHT_BLUE: '\x1b[44m',
                            COLOR_LIGHT_GREEN: '\x1b[42m',
                            COLOR_LIGHT_AQUA: '\x1b[46m',
                            COLOR_LIGHT_RED: '\x1b[41m',
                            COLOR_LIGHT_PURPLE: '\x1b[45m',
                            COLOR_LIGHT_YELLOW: '\x1b[43m',
                            COLOR_BRIGHT_WHITE: '\x1b[47m'
                            }
elif os.name == 'nt':
    import ctypes
    from ctypes import wintypes
    # Winbase.h
    WIN32_STD_OUTPUT_HANDLE = -11
    # Wincon.h and http://msdn.microsoft.com/en-us/library/windows/desktop/ms682088(v=vs.85).aspx#_win32_character_attributes
    WIN32_FOREGROUND_BLUE = 0x01          # Text color contains blue.
    WIN32_FOREGROUND_GREEN = 0x02         # Text color contains green.
    WIN32_FOREGROUND_RED = 0x04           # Text color contains red.
    WIN32_FOREGROUND_INTENSITY = 0x08     # Text color is intensified.
    WIN32_BACKGROUND_BLUE = 0x10          # Background color contains blue.
    WIN32_BACKGROUND_GREEN = 0x20         # Background color contains green.
    WIN32_BACKGROUND_RED = 0x40           # Background color contains red.
    WIN32_BACKGROUND_INTENSITY = 0x80     # Background color is intensified.

    WIN32_FG_COLOR_TABLE = {COLOR_BLACK: 0x00,
                            COLOR_BLUE: WIN32_FOREGROUND_BLUE,
                            COLOR_GREEN: WIN32_FOREGROUND_GREEN,
                            COLOR_AQUA: WIN32_FOREGROUND_BLUE | WIN32_FOREGROUND_GREEN,
                            COLOR_RED: WIN32_FOREGROUND_RED,
                            COLOR_PURPLE: WIN32_FOREGROUND_BLUE | WIN32_FOREGROUND_RED,
                            COLOR_YELLOW: WIN32_FOREGROUND_GREEN | WIN32_FOREGROUND_RED,
                            COLOR_WHITE: WIN32_FOREGROUND_BLUE | WIN32_FOREGROUND_GREEN | WIN32_FOREGROUND_RED,
                            COLOR_GRAY: WIN32_FOREGROUND_INTENSITY,
                            COLOR_LIGHT_BLUE: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_BLUE,
                            COLOR_LIGHT_GREEN: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_GREEN,
                            COLOR_LIGHT_AQUA: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_BLUE | WIN32_FOREGROUND_GREEN,
                            COLOR_LIGHT_RED: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_RED,
                            COLOR_LIGHT_PURPLE: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_BLUE | WIN32_FOREGROUND_RED,
                            COLOR_LIGHT_YELLOW: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_GREEN | WIN32_FOREGROUND_RED,
                            COLOR_BRIGHT_WHITE: WIN32_FOREGROUND_INTENSITY | WIN32_FOREGROUND_BLUE | WIN32_FOREGROUND_GREEN | WIN32_FOREGROUND_RED
                         }
    WIN32_BG_COLOR_TABLE = {COLOR_BLACK: 0x00,
                            COLOR_BLUE: WIN32_BACKGROUND_BLUE,
                            COLOR_GREEN: WIN32_BACKGROUND_GREEN,
                            COLOR_AQUA: WIN32_BACKGROUND_BLUE | WIN32_BACKGROUND_GREEN,
                            COLOR_RED: WIN32_BACKGROUND_RED,
                            COLOR_PURPLE: WIN32_BACKGROUND_BLUE | WIN32_BACKGROUND_RED,
                            COLOR_YELLOW: WIN32_BACKGROUND_GREEN | WIN32_BACKGROUND_RED,
                            COLOR_WHITE: WIN32_BACKGROUND_BLUE | WIN32_BACKGROUND_GREEN | WIN32_BACKGROUND_RED,
                            COLOR_GRAY: WIN32_BACKGROUND_INTENSITY,
                            COLOR_LIGHT_BLUE: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_BLUE,
                            COLOR_LIGHT_GREEN: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_GREEN,
                            COLOR_LIGHT_AQUA: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_BLUE | WIN32_BACKGROUND_GREEN,
                            COLOR_LIGHT_RED: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_RED,
                            COLOR_LIGHT_PURPLE: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_BLUE | WIN32_BACKGROUND_RED,
                            COLOR_LIGHT_YELLOW: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_GREEN | WIN32_BACKGROUND_RED,
                            COLOR_BRIGHT_WHITE: WIN32_BACKGROUND_INTENSITY | WIN32_BACKGROUND_BLUE | WIN32_BACKGROUND_GREEN | WIN32_BACKGROUND_RED
                         }

    class _CONSOLE_CURSOR_INFO(ctypes.Structure):
        # Wincon.h
        _fields_ = [('size', ctypes.wintypes.DWORD),
                    ('visible', ctypes.wintypes.BOOL)]

    class _CONSOLE_SCREEN_BUFFER_INFO(ctypes.Structure):
        # Wincon.h
        _fields_ = [('size', ctypes.wintypes._COORD),
                    ('cursorPosition', ctypes.wintypes._COORD),
                    ('attributes', ctypes.wintypes.WORD),
                    ('window', ctypes.wintypes.SMALL_RECT),
                    ('maximumWindowSize', ctypes.wintypes._COORD)]

        def __str__(self):
            return '%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d' % (self.size.Y, self.size.X,
                                               self.cursorPosition.Y, self.cursorPosition.X,
                                               self.attributes,
                                               self.window.Top, self.window.Left, self.window.Bottom, self.window.Right,
                                               self.maximumWindowSize.Y, self.maximumWindowSize.X)

    def GetConsoleScreenBufferInfo():
        # Wincon.h
        handle = get_win32_std_handle()
        csbi = _CONSOLE_SCREEN_BUFFER_INFO()
        ctypes.windll.kernel32.GetConsoleScreenBufferInfo(handle, ctypes.byref(csbi))
        return csbi

    def SetConsoleTextAttribute(attributes):
        # Wincon.h
        handle = get_win32_std_handle()
        ctypes.windll.kernel32.SetConsoleTextAttribute(handle, attributes)

    def get_win32_std_handle():
        # Winbase.h
        return ctypes.windll.kernel32.GetStdHandle(WIN32_STD_OUTPUT_HANDLE)


def hide_cursor():
    if os.name == 'posix':
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()
    elif os.name == 'nt':
        ci = _CONSOLE_CURSOR_INFO()
        handle = get_win32_std_handle()
        # Wincon.h
        ctypes.windll.kernel32.GetConsoleCursorInfo(handle, ctypes.byref(ci))
        ci.visible = False
        ctypes.windll.kernel32.SetConsoleCursorInfo(handle, ctypes.byref(ci))


def show_cursor():
    if os.name == 'posix':
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()
    elif os.name == 'nt':
        ci = _CONSOLE_CURSOR_INFO()
        handle = get_win32_std_handle()
        # Wincon.h
        ctypes.windll.kernel32.GetConsoleCursorInfo(handle, ctypes.byref(ci))
        ci.visible = True
        ctypes.windll.kernel32.SetConsoleCursorInfo(handle, ctypes.byref(ci))


def print_color(message, fg_color=None, bg_color=None, newline=True):
    if os.name == 'posix':
        result = ''
        if fg_color is not None and fg_color in POSIX_FG_COLOR_TABLE:
            result = result + format(POSIX_FG_COLOR_TABLE[fg_color])
        if bg_color is not None and bg_color in POSIX_BG_COLOR_TABLE:
            result = result + format(POSIX_BG_COLOR_TABLE[bg_color])
        result = result + message + POSIX_COLOR_RESET
        if newline:
            print result
        else:
            print result,
    elif os.name == 'nt':
        # get default csbi
        default = GetConsoleScreenBufferInfo().attributes
        default_fg = default & 0x0f
        default_bg = default & 0xf0
        fg = default_fg
        bg = default_bg
        if fg_color is not None and fg_color in WIN32_FG_COLOR_TABLE:
            fg = WIN32_FG_COLOR_TABLE[fg_color]
        if bg_color is not None and bg_color in WIN32_BG_COLOR_TABLE:
            bg = WIN32_BG_COLOR_TABLE[bg_color]
        SetConsoleTextAttribute(fg | bg)
        if newline:
            print message
        else:
            print message,
        SetConsoleTextAttribute(default)
    else:
        if newline:
            print message
        else:
            print message,


if __name__ == '__main__':
    # test cursor
    print '### Cursor Test ###'
    import time
    hide_cursor()
    print 'Test hide_cursor() for 3 sec...'
    time.sleep(3)
    show_cursor()
    print 'Test show_cursor() for 3 sec...'
    time.sleep(3)
    # test color
    print '\n### Color Test ###'
    print_color('FG ' + COLOR_BLUE, fg_color=COLOR_BLUE)
    print_color('FG ' + COLOR_GREEN, fg_color=COLOR_GREEN)
    print_color('FG ' + COLOR_RED, fg_color=COLOR_RED)
    print_color('BG ' + COLOR_BLUE, bg_color=COLOR_BLUE)
    print_color('BG ' + COLOR_GREEN, bg_color=COLOR_GREEN)
    print_color('BG ' + COLOR_RED, bg_color=COLOR_RED)
    print_color('FG ' + COLOR_LIGHT_AQUA + ', BG ' + COLOR_PURPLE, fg_color=COLOR_LIGHT_AQUA, bg_color=COLOR_PURPLE)
    print_color('FG ' + COLOR_PURPLE + ', BG ' + COLOR_BRIGHT_WHITE, fg_color=COLOR_PURPLE, bg_color=COLOR_BRIGHT_WHITE)
    print_color('FG ' + COLOR_LIGHT_YELLOW + ', BG ' + COLOR_BLUE, fg_color=COLOR_LIGHT_YELLOW, bg_color=COLOR_BLUE)
