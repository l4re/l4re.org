.. _contributing:

Contributing to L4Re
********************

.. toctree::
   :hidden:

   styleguide.md

We welcome contributions to the L4Re project!

Contribution Policy
===================

All contributions to the L4Re project must be submitted as patches
accompanied by a ``Signed-off-by:`` line in the commit message.

By adding this line, you confirm that you have the right to submit the patch
under the project’s license and that you agree to the `Developer’s
Certificate of Origin (DCO) <https://developercertificate.org/>`_. If
you're unfamiliar with DCO, please consult this page. It is really short.

A typical commit message looks like this:

.. code::

   Short summary of the change

   More detailed explanation if necessary.

   Signed-off-by: Your Name <your.email@example.com>


Please ensure every patch carries at least one ``Signed-off-by:`` line.
You may also consult git commit's ``-s`` option for further support in
handling this.


Trivial Fixes and Hints
-----------------------

For small fixes and changes, such as typo fixes and a few lines, you can also
create an issue and we fix it. That is typically the faster process overall.

Patch Process
=============

All patches must have a unique Gerrit ``Change-Id:`` tag. This tag is
automatically added by a commit hook. If you followed the
:ref:`build_with_make` tutorial, the Gerrit hook should be in place already.
Otherwise, you can fetch and install the git hook with the following steps
manually in your cloned repository:

.. sourcecode:: shell

    hook="$(git rev-parse --git-dir)/hooks/commit-msg"
    curl -s -o "$hook" https://raw.githubusercontent.com/GerritCodeReview/gerrit/refs/heads/stable-3.14/resources/com/google/gerrit/server/tools/root/hooks/commit-msg
    chmod a+x "$hook"

In order to maintain the high quality of the codebase we at Kernkonzept
review each patch before it is submitted to the main branch. We might
consider to do more work on the change for it to be ready to merge.

We will continue to act as gatekeepers for pushing changes into the L4Re
repositories to maintain an overall high quality and to maintain security
and safety procedures we are obliged to do for L4Re.

That means that each contribution will be reviewed by Kernkonzept developers
internally, before it gets merged to our internal main branch and eventually
gets published into the public repositories. This can take some
time. We are happy to discuss options to accelerate this process.

If you seek to make a large or involving change please open an issue up front
and start discussing the details with us.

Submitting patches
==================

This guide contains a collection of suggestions for a person or company not
familiar with our development process to help getting your contribution
accepted.

Describe your changes
---------------------

Describe the problem your patch is solving. If your patch fixes a
known bug, refer to that issue by number or URL. After describing the problem,
describe in technical detail what you are actually doing to fix it.

Separate your changes
---------------------

Separate each logical change into a separate patch that can be verified by our
reviewers. Solve one problem per patch.

If you divide a change into a series of patches, take special care to ensure
that the project builds and runs properly after each single patch of the series
is applied.

If one patch depends on another patch simply note **"this patch depends on
patch X"** in the patch description.

Style-check your changes
------------------------

Check your patch for basic style violations. See our :ref:`contrib-styleguide`
for guidance.

Respond to review comments
--------------------------

Most contributions will almost certainly receive review comments. Please
respond to those comments to show that you care about you contribution.
