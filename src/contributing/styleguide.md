(contrib-styleguide)=

# L4Re Coding Style

Here we describe our preferred coding style for L4Re and the microkernel. The
structure and some of the rules are derived from the Linux kernel coding style.
In general a common coding style is about maintaining readability and
maintainability of a shared code base.

## Coding style changes

In general, we do not change code just to fix the coding style. This obfuscates
the history of the line without adding value.
The coding style shall be fixed when working on the code and adding value to
it.

## Indentation

We don't use tabs but spaces for indentation. A new block of control is
indented by 2 spaces. To avoid double-indentation in switch statements it is
allowed to align the ***{*** and the ***case*** labels in the same column.
```c
switch (action)
  {
  case 1:
    do_something();
    break;

  case 2:
    {
      do_another_thing();
      break;
    }
  default:
    break;
  }
```

Indentation with multi-line expressions:
```c
l4_ipc_send(env->main_thread().cap(), l4_utcb(), l4_msgtag(0, 0, 0, 0),
            L4_IPC_NEVER);
```

### Namespaces

Namespaces must be started using:
```c++
namespace Xyz {

or

namespace Xyz
{
```

Multiple namespaces shall be started on a single line if they are closed
on a single line:
```c++
namespace Xyz { namespace Abc {
  ...
}} // namespace Xyz::Abc
```

The contents of a namespace must be indented by two spaces (except when
covering a whole file):
```c++
namespace Xyz { namespace Abc {
  This_is_some_statement;
}} // namespace Xzy::Abc
```

The contents of a namespace shall not be indented when the namespace covers a
complete file, this means the file may contain only preprocessor directives
before and after the namespace declaration:
```c++
#pragma once

#include <cstdio>

namespace X {

Code;
...

}
```

It is discouraged to use statements like ```using L4Re::chksys;``` or ```using
L4Re::chkipc;``` even if you intent to save space: With the namespace in front
of these global functions it is quite clear that this is the global function
and not some local overloading.

## Line Breaks

Our line length limit is 80 columns. Statements longer than 80 columns should
be broken into sensible chunks. One exception to this rule is to never break
user-visible strings because that breaks the ability to grep for them.

It is not allowed to put multiple statements on a single line. It is not
allowed to put multiple assignments on a single line.  The only exceptions is
for switch statements where case, statement and break may go on a single line
provided the line remains shorter than 80 characters.

```c++
switch (foo)
  {
  case 1: bar = "spring"; break;
  case 2: bar = "summer"; break;
  case 3: bar = "fall"; break;
  default: bar = "winter"; break
  }
```

A single statement that follows an if-condition is put on its own line.
```c++
if (condition)
  break;

if (condition2)
  return 0;
```

When breaking long lines with operators, the operator goes at the beginning of
the new line.
```c++
if ((flags & FOO)
    || (flags & BAR))
```

Don't leave whitespace at the end of lines.

## Function Definitions

In function definitions outside classes the return type should go on its own
line

```c++
static int
Magic::create_something_wonderful(int random)
{
  return magic_happens(random);
}
```

## Class Definitions

Base classes can be put in the same line as the class name, if they fit.
Otherwise, each base class must go on its own line.

So write either

```c++
class Foo : public Bar, public Baz
{
  // stuff
};
```

or

```c++
class Foo
: public Bar,
  public Baz
{
  // stuff
};
```

Classes should be structured as follows:

```c++
class Foo
{
  // enums and structs

public:
  // Ctors
  // public functions

protected:
  // protected functions

private:
  // private functions

  // public, protected, and private variables at the end.
};
```

## Braces

Opening and closing braces are placed on individual lines and they are indented
by 2 spaces.
```c++
if (foo)
  {
    bar();
    foo();
  }
else
  {
    baz();
    biz();
  }
```

One exception to this rule is when a new function, class, namespace or enum is
declared. Then the indentation is omitted.

The body of very short inline functions inside class definitions may go on a
single line. Add spaces around the braces:

```c++
class Foo
{
  int is_a_foo()
  { return true; }

};
```

The braces of an empty class body go on a new line below the class declaration
```c++
class Foo
{};
```

## Parenthesis

Use parenthesis only in one of the following cases:

* to improve readability in cases where knowledge of operator precedence is
  uncommon
* when expressions get complicated and consist of multiple sub-expressions and
  it is not possible to split up the expressions
* when a compiler warning demands it

Common knowledge of operator precedence includes:

* ```==``` and ```!=``` are stronger than ```&&``` and ```||```
* ```=``` is less strong than common expressions

Examples in which no parenthesis are needed:
```c++
enum
{
  Name = expression
};

int x = expression;

int a = x * y + z;

if (a == b && c == d) ...
if (a != b || c == d) ...
```

## Spaces

A space is inserted after most keywords. Exceptions to this rule are keywords
which are used like functions such as `sizeof` and `typeof`.

Use one space around the binary and ternary operators:
```=  +  -  <  >  *  /  %  |  &  ^  <=  >=  ==  !=  ?  :```

Don't put space after the unary operators:
```&  *  +  -  ~  !```

Don't put space before the postfix increment and decrement unary operators:
```++ --```

Don't put space after the prefix increment and decrement unary operators:
```++ --```

## Naming

We don't use camel-case. Names, types and constants start with a capital letter
and concatenate multiple words using ***_***.
```c++
namespace Util
{
class Br_manager
{
  enum Some_enum
  {
    Item_1,
    Item_2
  };
};
}
```

Local variable names should be descriptive and short. Using one-letter names is
considered bad as it hinders grep'ing.

Public members start with a lowercase letter. Private members start with an
underscore.
```c++
class Rect
{
public:
  l4_uint32_t x;
  l4_uint32_t y;

private:
  l4_uint32_t _area;
};
```

Usually you should use `class` for class definitions.  `struct` may be only
used for classes when all members of a class are public.

In C code, the `_t` suffix denotes a type, e.g. `l4_uint32_t`, `l4_addr_t`.

If a C++ class name ends with `_t` is must take a template parameter. It is not
mandatory to use a `_t` suffix on a class taking template parameters.

## Naming of L4Re service files

To enable the reader to easily recognize the puprose of a non-binary file used
in L4Re, e.g in the modules list or on a service's command line, their suffix
shall denote either the service the file is used with or the purpose it
serves.

| Service | Purpose | Suffix |
|---------|---------|--------|
| ned | configuartion script | .ned  |
| ned | lua library          | .lua  |
| io  | hardware description | .io   |
| io  | vbus description     | .vbus |
| modules.list    | file listing | .list |
|  |  |  |

These file names are used in the `modules.list` as well as in the `SRC_ASSETS_*`
rules in a Makefile.

## Loops

```c++
while (condition)
  {
    multiple;
    statements;
  }

while (cond)
  single_statement;

for (unsigned i = 0; i < 10; ++i)
  {
    multiple;
    statements;
  }

for (...)
  single_statement;

do
  {
    code;
  }
while (condition);
```

## Endless Loops

```c++
for (;;)
  {
    code...;
  }
```

## Variable Declarations

Put the `const` keyword after the affected type. Put a space before a pointer
asterisk `*` and attach it to the declared identifier or a following `const`.

Motivation: Everything left of `const` is constant:
```c++
FOO const *const
```
* The left-most `const` makes `FOO` a constant object.
* The right-most `const` makes the pointer constant.

Examples:
```c++
int i;
int const c = 42;
int *p1;
int *const p3 = &i;        // const pointer to a (non-const) int
int const *p2;             // pointer to a const int
int const *const p4 = &c;  // const pointer to a const int
```

### auto
Use `auto` only when it improves readability.

* Do not use `auto` when the deduced type is not immediately obvious from the
  initializer or the surrounding context.
* Use `auto` in particular when it significantly shortens a line and the type is
  obvious or insignificant (for example for iterators, lambdas, or verbose
  template types).

## C/C++ Integral Constants

Use `enum` types to define integral constants wherever possible. Avoid `static
const` and `static constexpr`.

## C++ keywords

We use `noexcept` instead of `throw()`.

## Resource Management and Memory Allocation

Resources should be managed according to the
[RAII paradigm](https://en.wikipedia.org/wiki/Resource_acquisition_is_initialization).
Avoid explicit malloc/free/new/delete in C++ code.

`malloc`/`free` must not be used in C++.

## Using Exceptions

L4Re applications may use exceptions only to detect unexpected error conditions.
These are errors that have one of two consequences:

* the application prints an error and exits
* in a server loop, processing of the current client request is aborted and
  an error is returned to the client.

Install the special L4 terminate handler from `#include <terminate_handler-l4>`
to ensure that exceptions print a meaningful message. You can also add a
catch-all try-catch in the main function. As a rule, this should be the only
try-catch you should need in your application.

## Defensive Programming

### Type Casting

Code must be written in a way that minimizes the need for casts. In particular,
consider the value range and signedness for POD variables and be mindful of
narrowing casts.

When having to cast, always use C++-style casts. The following rules apply:

* when using `dynamic_cast` the result must be checked for `nullptr`
* `reinterpret_cast` may only be used in dedicated allocator functions
  that provide typed memory

### Error Checking of Input

Do not trust the content of received IPC. Use the RPC framework to ensure
correct handling of the IPC buffer and check the value range of parameters.

When a function returns an error, the caller must always check for the error
condition. You may use `L4Re::chksys()` to convert the error to an exception.

### Assertions

**Do** use assertions to

* express pre- and postconditions of functions,
* check for programming errors that are not expected to ever occur.

**Don't** use assertions to

* check for errors that may be expected in production
* stop the program on an unexpected condition.

Assertion must not have side effects. The program must work safely when they
are disabled. In particular, the core components must be able to handle
unexpected conditions in a way that the system remains in a safe state.

### goto, setjmp, longjmp

Do not use `goto`, `setjmp` or `longjmp`.

The only exception is in C code: `goto` may be used to clean resources during
error handling.

## Commenting

In C files and C compatible header files we use `/* ... */`, in C++ code we use
`// ...` for comments.

## 3rd party code

If we modify 3rd party code e.g. a library or Linux we apply the coding style
rules from the 3rd party project.

# GNU Makefiles

Use two spaces for indentation of conditionals:
```makefile
ifeq ($(ARCH),mips)
  SRC_CC_test_$(ARCH)_thread_vcpu_ext += mips_thread_vcpu_ext.cc
endif
```

# Git commit messages

Git commit messages have a maximum width of 72 characters for both the summary
and the description. The maximum width may be exceeded only in exceptional
cases.

The commit message contains at least one _Signed-off-by:_ line.

# Doxygen Styles

* we use the `\command` Syntax
* we use doxygen's Markdown instead of HTML or doxygen commands

## Brief and Detailed Documentation

* we have autobrief enabled, so don't use `\brief`
* place an empty line after the brief description
* The detailed description is placed after the documentation of the return
  values. Put an empty line before the detailed description.

## Parameter Documentation

* parameter names must be left-aligned, as well as parameter descriptions
* at least two spaces between parameter name and description
* Parameter directions:
    * the default is *Input*, just use plain `\param`
    * `\param[in,out]` is used if the parameter is used to pass arguments into
      the function and the function also returns values through this parameter
    * `\param[out]` is used if the called function stores or returns data
      through this parameter
* These rules apply to template parameters as well.

## Return Value Documentation

* place an empty line between parameter and return value documentation
* use `\retval` in case the function may return different return values and if
  possible describe each of them

## Example

```
/**
 * A brief description of the function
 *
 * \tparam        T     Description of template parameter.
 * \param         par1  Description of parameter 1.
 * \param[out]    par2  Description of parameter 2. Caller must allocate memory.
 * \param[in,out] par3  Description of parameter 3.
 *
 * \retval 0           The function returned successfully.
 * \retval -L4_ENOMEM  Not enough memory to create the new kernel object.
 *
 * \pre Add expected conditions here. Expectations for specific parameters
 *      may also be added in the respective param section.
 *
 * \post Describe conditions here that the caller can expect after
 *       execution. Don't forget to mention when they are only valid
 *       if execution was successful.
 *
 * Longer detailed description of the function. This may span multiple
 * paragraphs. But the line length is limited to 80 characters.
 */
```

# L4Linux Coding Style

The L4Linux coding style mirrors the Linux coding style. However there are a
few inaccuracies that need to be made clear:

## Indentation

When indenting parameters, you shall use *tabs* to reach the indent level of
the function, and then use *spaces* to align the parameter to the first one.
The reason is that if you used a mixture of tabs and spaces, the indenting of
the function parameter breaks.
