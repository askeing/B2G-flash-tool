#!/usr/bin/python

from Tkinter import Tk, Frame
import os
from page import ListPage, AuthPage

TITLE_FONT = ("Helvetica", 18, "bold")


class FlashApp():
    def __init__(self, *args, **kwargs):
        '''
        Generate base frame and each page, bind them in a list
        '''
        self.root = Tk()
        self.frames = []
        container = Frame(master=self.root)
        container.grid_rowconfigure(0, weight=1)
        container.grid_columnconfigure(0, weight=1)
        container.pack(side="top", fill="x", expand=False)
        self.container = container

    def setFrameList(self, list):
        self.frames = list
        for idx, val in enumerate(self.frames):
            val.index = idx
            val.grid(row=0, column=0, sticky="nsew")

    def setupView(self, data):
        #NOTE: Please overwrite this function to provide custom view
        listPage = ListPage(parent=self.container, controller=self)
        listPage.setupView(data=data)
        authPage = AuthPage(parent=self.container, controller=self)
        authPage.setupView(
            "Account Info",
            '',
            '')

        self.setFrameList([
            authPage,
            listPage,
            ])
        self.transition()

    def setAuth(self, page, user, pwd):
        ## pass auth parameters
        self.transition(page)

    def transition(self, page=None):
        if page is None:
            self.frames[0].lift()
        elif page.index < len(self.frames) - 1:
            self.frames[page.index + 1].lift()

    def quit(self):
        '''
        Halt the program
        '''
        pass

    def doFlash(self, params):
        #TODO: run flash here
        print(params)
        self.quit()

    def getPackages(self, src):
        return []
        pass


if __name__ == '__main__':
    data = {}
    with open('../test/flash_info.data') as f:
        data = eval(f.read())
    prog = FlashApp()
    app = prog.container
    prog.setupView(data)
    from sys import platform as _platform
    if _platform == 'darwin':
        os.system("/usr/bin/osascript -e \'tell app \"Find\
er\" to set frontmost of process \"Pyt\
hon\" to true\'")
    app.mainloop()
