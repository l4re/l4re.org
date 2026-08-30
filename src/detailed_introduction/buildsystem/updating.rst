Updating
********

In :doc:`/getting_started/make` you learned how to check out the L4Re
source tree using ``ham``. Similarly you can use ``ham`` for updating the
source tree:

.. sourcecode:: shell

   ham sync

This will fetch and checkout the latest changes in all repositories.

Sometimes it is necessary to reconfigure your build directories:

.. sourcecode:: shell

   make oldconfig

This is the case when your compiler or some config options changed.

More Ham Functionality
======================

Since ``ham`` is only a wrapper around git, it has some more features you might
want to use:

Print information about changes in the build tree

.. sourcecode:: shell

   ham status

Repositories with changes are likely to fail the ``sync`` operation. It can be
handy to see where you have to manually resolve sync failures with the
``status`` operation.

A more generic functionality is the ``forall`` operation, which executes an
arbitrary command in each repository's root directory. A different approach for
syncing your source tree is the following.

.. sourcecode:: shell

   ham forall -- git fetch
   ham forall -p -- git rebase

.. hint::

   The ``-p`` option prints the name of each repository before executing the
   provided command. This way you can directly see where conflicts occur.


Repositories All The Way Down
=============================

In the end, these are just git repositories which you can update as you like.
You don't have to use ``ham``. You should, however, update them all at once
because APIs are used across the repos. Only update a single repo if you know
what you're doing.
