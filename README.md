awesome config
==============

My personal configuration for awesome WM (awesome-3.5)

I use the following modules:

* [tyrannical](https://github.com/Elv13/tyrannical)
  * dynamic tagging
* [blingbling](https://github.com/cedlemo/blingbling)
  * widget library and themes
* [vicious](https://github.com/Mic92/vicious)
  * other widget library
* [lain](https://github.com/copycat-killer/lain)
  * other (!) widget library

I also use a modified version of [APW](https://github.com/mokasin/apw).
My theme is a modified version of japanese2 from [blingbling](https://github.com/cedlemo/blingbling).
Some of the icons come from the libre icon set [iconic](https://github.com/iconic/open-iconic).

The libraries come from various sources, including:
* keydoc.lua from [https://github.com/vincentbernat/awesome-configuration].
* inspect.lua from [https://github.com/kikito/inspect.lua]
* xrandr.lua from awesome wiki [http://awesome.naquadah.org/wiki/Using_Multiple_Screens]

With a screenshot:
![screen shot](https://github.com/downloads/getzze/awesome_config/screenshot.png)

To use it, just clone this repository and install the submodules:
```
cd ~/.config
git clone https://github.com/getzze/awesome_config
mv awesome_config awesome
cd awesome
# Update submodules
git submodule update --init --recursive
# Generate menu with xdg-menu
xdg_menu --format awesome --root-menu /etc/xdg/menus/arch-applications.menu >~/.config/awesome/archmenu.lua
```
