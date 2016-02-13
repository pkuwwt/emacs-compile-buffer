# emacs-compile-buffer
Compile buffer with one key

## Installation

Copy `compile-buffer.el` to `~/.emacs.d/site-lisp`, and add following lines in `~/.emacs`:

    (add-to-list 'load-path "~/.emacs.d/site-lisp/")
    (load "compile-buffer.el")

## Usage

  * `<F5>` to compile the buffer
  * `<F6>` to run the result
  
## Advanced usage

### Testing for C/CPP
When you want to test a source code, you need a main function. However, there is only one main entry in a project. So if you need to test a source file, you usually write an additional testing code.

In `compile-buffer.el`, I provide a `#ifdef COMPILE_DEBUG` macro to wrap a main function, which does not affect the project but can be compiled by `compile-buffer.el`, because I add `-DCOMPILE_DEBUG` in the command line for compiling. There is a working example:

    #include <iostream>
    int func() { return 1; }
    #ifdef COMPILE_DEBUG
    int main(int argc, char* argv[]) {
        std::cout << "hello world, " << func() << std::endl;
        return 0;
    }
    #endif

### Configurable libraries for C/CPP
If you compile the current buffer by pressing `<F5>`, `compile-buffer.el` will automatically figure out the flags needed for specific library. 

In specific, there is a pre-defined list of pairs called `CB-libs-pattern-flags`, in which each pair `(pattern, flags)` is used to configure the flags for compilation. If `pattern` is contained in current buffer, then `flags` will be added to command line.

We can clear the default `CB-libs-pattern-flags` by 

    (CB-clear-lib-pattern-flags)
    
And add user-defined pairs by `CB-add-lib-pattern-flags`, for example,

    (CB-add-lib-pattern-flags "GL" " -lGL -lGLU -lglut ")

### Additional flags for C/CPP
Although we can configure the flags in `.emacs`, however, there may be occasionally some special dependencies. Thus, we need source-specific configuration.

We can use `// COMPILE_DEPENDS:` to add additional flags, for example

    // COMPILE_DEPENDS: -L/usr/include/GL -lm other_source.cpp

## Limitation

I only focus on `C/CPP`, `LaTeX` and `python`, and extensions are needed for other programming languages.
