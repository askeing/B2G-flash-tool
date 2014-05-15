#!/usr/bin/python

import os
import sys
from utilities.arg_parse import Parser
from controller.console_controller import ConsoleApp


def main():
    options = Parser.pvtArgParse(sys.argv[1:])
    if options.window:
        try:
            from controller.tk_controller import FlashApp
        except ImportError:
            print '### Please install Tkinter, a GUI Package of Python.\n    ex: Ubuntu user can type "sudo apt-get install python-tk" to install Tkinter.'
            sys.exit(-1)
        prog = FlashApp()
        app = prog.container
        prog.setupView()
        from sys import platform as _platform
        if _platform == 'darwin':
            os.system("/usr/bin/osascript -e \'tell app \"Finder\" to set frontmost of process \"Python\" to true\'")
        app.mainloop()
    else:
        try:
            prog = ConsoleApp()
            prog.run()
        except KeyboardInterrupt:
            print ''
            print '### Quit'
            sys.exit(0)

if __name__ == '__main__':
    main()
