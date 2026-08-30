Configure L4Re and the Microkernel
**********************************

Both L4Re and the L4Re Microkernel use Linux's Kconfig system for configuration.
If you have worked with Linux's configuration system before this should feel
familiar to you.

Configuration using the standard console interface
--------------------------------------------------

Once you've created a build directory and navigated into it. You can run the
following command to configure your build::

  make menuconfig

In this interface you navigate around using the arrow keys. If you want to
search for an option you can type ``/`` to search.

Entries with a ``--->`` at the end are sub menus which can be entered using the
Enter key.

Entries that begin with a ``[ ]`` or ``[*]`` are boolean options which can be
toggled using the space bar.

Entries that begin with a value in parenthesis are options that require an
integer or string value. These can also be adjusted by pressing the Enter key.

More information about a particular option can be accessed using the ``?`` key.

Configuration using the alternative ncurses interface
-----------------------------------------------------

There is an alternative ncurses interface which can be started as follows::

  make nconfig

It behaves similarly to the standard console interface.

Configuration using the GTK interface
-------------------------------------

To start the GTK GUI for configuration, you can run the following command::

  make gconfig

A window will pop up that can be navigated using the mouse cursor.

Configuration using the Qt interface
------------------------------------

To start the Qt GUI for configuration, you can run the following command::

  make xconfig

A window will pop up that can be navigated using the mouse cursor.

Reconfiguration after updating the sources
------------------------------------------

When updating your sources new options might have been introduced in the
meantime. After updating your sources you can run the following command and the
build system will show any newly introduced options::

  make oldconfig

Default configs (defconfig)
---------------------------

Kconfig can save a separate configuration file with all the options removed that
have their default values set, commonly known as a defconfig. This is useful if
you want to reuse your configuration in the future, but want to have any changed
defaults as well. To generate such a defconfig run the following command::

  make savedefconfig

This command will generate a file called ``defconfig`` in the root of your build
directory.

When you want to reuse such a defconfig in the future, you can copy its contents
to the corresponding config file (for L4Re this file is called ``.kconfig``, for
the L4Re microkernel this file is called ``globalconfig.out``)

After copying its contents, you should run the following command to apply all
the current defaults::

  make olddefconfig
