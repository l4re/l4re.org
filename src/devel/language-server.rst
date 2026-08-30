Language Server Support
=======================

Within L4Re's build infrastructure, language server support (LSP) is
available for both the microkernel and user-level.

Generally, a language server like ``clangd`` needs an input file
``compile_commands.json`` to get information on how files are processed.


User-level
----------

User-level components are built out of combined source tree. The build
system generates a ``compile_commands.json`` file by calling this from your
build directory:

.. sourcecode:: shell

   $ make compile_commands.json


After this, a ``compile_commands.json`` file is available in the L4Re
source(!) directory.


Microkernel
-----------

For the microkernel, you call the same in a build directory of the microkernel:

.. sourcecode:: shell

   $ make compile_commands.json


Which generates a ``compile_commands.json`` in the build directory.

There is one more thing to consider regarding LSP support for the
microkernel. As it uses ``preprocess`` to generate the files to be compiled by
the compiler, the source code files contain information that cannot be
directly understood by LSP servers. However, there is a proxy available that
translates between the actual source code files and the language server:
`fiasco-lsp <https://github.com/l4re/fiasco-lsp>`_.
