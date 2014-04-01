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

        listPage = ListPage(parent=container, controller=self)
        listPage.setupView()
        listPage.setDeviceList([
            "hamachi",
            "leo",
            "helix",
            "nexus4",
            "tarako"
            ])
        listPage.setVersionList([
            "master",
            "aurora",
            "1.2",
            "1.3",
            "1.4"
            ])
        listPage.setPackageList([
            "Gecko/gaia",
            "Gecko",
            "gaia",
            "full flash"
            ])
        listPage.setEngList([
            "Eng",
            "user",
            ])
        authPage = AuthPage(parent=container, controller=self)
        authPage.setupView(
            "Account Info",
            '',
            '')

        self.frames = [
            authPage,
            listPage,
            ]
        for idx, val in enumerate(self.frames):
            val.index = idx
            val.grid(row=0, column=0, sticky="nsew")
        self.transition()
        self.container = container

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


if __name__ == '__main__':
    app = FlashApp().container
    from sys import platform as _platform
    if _platform == 'darwin':
        os.system("/usr/bin/osascript -e \'tell app \"Find\
er\" to set frontmost of process \"Pyt\
hon\" to true\'")
    app.mainloop()
