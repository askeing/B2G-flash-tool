import sys
import os


def hide_cursor():
    if os.name == 'posix':
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()


def show_cursor():
    if os.name == 'posix':
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()
