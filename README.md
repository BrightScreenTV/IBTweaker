# IBTweaker

## A small, very simple utility to change [ultimately] various parts of a `.storyboard` file as used in Xcode.

### PLEASE NOTE: this little app gives you the ability to alter your storyboard. You do it at your own risk!! It's worked OK for me, but make sure you backup your project before using it! _You have been warned._

***

I was getting fed up with wanting to change the font used in a UI halfway through a project. There seemed to be no way of easily doing this in Xcode. Yes, you can select multiple items and some of the paramters can be changed in one go, but it's not always that easy.

With `IBTweaker`, you open a `.storyboard` file, choose a font from the drop down menu and type a size in the box next to it.

Clicking the bottom button will make `IBTweaker` to use `REGEX` and replace any entry in the file that matches the pattern:

`<font\\skey=\"font\"\\s(metaFont=\"|size=\")(.+)>`

Save the file and when you open XCode (or if you have it open and you've loaded a storyboard being currently used) you'll see the UI updated with a new font.
