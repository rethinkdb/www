---
layout: post
title: Make debugging easier with custom pretty-printers
--- 

# What's good about pretty-printers

One of the best features in Gdb 7.0+ is the ability to write pretty-printers in
Python. Instead of printing a vector and seeing this:

```cpp
$1 = {
  <std::_Vector_base<int,std::allocator<int> >> = {
    _M_impl = {
      <std::allocator<int>> = {
        <__gnu_cxx::new_allocator<int>> = {<No data fields>}, <No data fields>}, 
      members of std::_Vector_base<int,std::allocator<int> >::_Vector_impl: 
      _M_start = 0x0, 
      _M_finish = 0x0, 
      _M_end_of_storage = 0x0
    }
  }, <No data fields>}
```

I can now see this:

```cpp
$1 = std::vector of length 0, capacity 0
```
<!--more-->

Much better!

# Background on pretty-printers

Gdb has never been good at pretty-printing complex data structures, but that's
finally changing. Project Archer is a Gdb development branch primarily
dedicated to improving the C++ debugging experience. For me their most exciting
project is PythonGdb, which aims to integrate Python scripting into Gdb. You
can do cool things like define your own Gdb commands, script gdb in Python and
write pretty-printers in Python. We do our debugging in Gdb and we've come to
rely on our pretty-printers.

# What has been done so far

If all you're looking for is pretty-printers for STL containers, you're in
luck. ProjectArcher has [written pretty-printers for all the containers in the
STL][stl]. If you have Gdb 7.0+, you can have decent printers in a couple of
minutes. If you don't have GDB 7.0+, it's a short build.

[stl]: http://sourceware.org/gdb/wiki/STLSupport

# What is still to be done

The problem is, printing out classes and structs is still an issue. If you've
defined some complex struct, a pretty-printer can save you a lot of time
squinting at your screen (or writing print functions). ProjectArcher hasn't
written pretty-printers for structs, maybe because each struct is different.
But it should be possible to write a generic function for printing structs:
most of the time, you just want to print out the values of the members in the
struct. All you need is a decent generic pretty-printer. With that in mind, I
decided to write a pretty-printer that could be used for any struct.

Before we look at the code, I suggest reading Tromey's blog post on [pretty
printing in Gdb][1] if you don't know the basic idea. To start off, here's a
basic pretty printer that prints the names and types of each member in a class:

[1]: http://tromey.com/blog/?p=524

```python
class GenericPrinter:
    def __init__(self, val):
        self.val = int(val)
 
    def to_string(self):
        return "Generic object with the following members:"
 
    def children(self):
        for field in self.val.type.fields():
            yield field.name, str(field.type)
```

That's pretty easy, we just iterate over the fields. If we want to print out
the values, things get a little trickier. We need to check the type of the
field and print it accordingly. For example, here's how we could check for
built-in types:
  
```python
for field in self.val.type.fields():
    key = field.name
    val = self.val[key]
    if val.type.code == Gdb.TYPE_CODE_INT:
        yield key, int(val)
    elif val.type.code == Gdb.TYPE_CODE_FLT or val.type.code == Gdb.TYPE_CODE_DECFLOAT:
        yield key, float(val)
    elif val.type.code == Gdb.TYPE_CODE_STRING or val.type.code == Gdb.TYPE_CODE_ARRAY:
        yield key, str(val)
    else: yield key, val
```

For each member, we need to check it's type and yield accordingly.

Pointers are also tricky. Gdb usually just prints the address of the pointer,
but usually, I want to know more about the object that it's pointing to. So we
can dereference the pointer:

```python
if val.type.code == gdb.TYPE_CODE_PTR or val.type.code == gdb.TYPE_CODE_MEMBERPTR:
    yield key, val.dereference()
```

But that's not enough. You could have a null pointer:

```python
if val.type.code == gdb.TYPE_CODE_PTR or val.type.code == gdb.TYPE_CODE_MEMBERPTR:
    if not val: yield key, "NULL"
    else: yield key, val.dereference()
```

The real problem is pointers that point to garbage data. There's no clean way
to check for those, so we hack it by trying to convert the deference to a
string. If we get a RuntimeError, we know there's no object there:
    
```python
if val.type.code == gdb.TYPE_CODE_PTR or val.type.code == gdb.TYPE_CODE_MEMBERPTR:
    if not val: yield key, "NULL"
    else:
        try:
            str(val.dereference())
            yield key, val.dereference()
        except RuntimeError: 
            yield key, "Cannot access memory at address " + str(val.address)
```

We can also print out the members of all the base classes of a given class by
writing a function that calls itself recursively:

```python
def process_kids(state, PF):
    for field in PF.type.fields():
        key = field.name
        val = PF[key]
        if field.is_base_class and len(field.type.fields()) != 0:
            for k, v in process_kids(state, field):
                yield key + " :: " + k, v
        else:
            yield key, val
```

The full code looks something like this:
    
```python
import re
import gdb
 
def lookup_function (val):
    "Look-up and return a pretty-printer that can print val."
    # Get the type.
    type = val.type
 
    # If it points to a reference, get the reference.
    if type.code == gdb.TYPE_CODE_REF:
        type = type.target ()
 
    # Get the unqualified type, stripped of typedefs.
    type = type.unqualified ().strip_typedefs ()
 
    # Get the type name.    
    typename = type.tag
 
    if typename == None:
        return None
 
    # Iterate over local dictionary of types to determine
    # if a printer is registered for that type.  Return an
    # instantiation of the printer if found.
    for function in sorted(pretty_printers_dict):
       if function.match (typename):
           return pretty_printers_dict[function] (val)
 
    # Cannot find a pretty printer.  Return None.
    return None
 
 
class GenericPrinter:
    def __init__(self, val):
        self.val = val
 
    def to_string(self):
        return "Generic object with the following members:"
 
    def children(self):
        for k, v in process_kids(self.val, self.val):
            for k2, v2 in printer(k, v): yield k2, v2
 
 
def process_kids(state, PF):
    for field in PF.type.fields():
        if field.artificial or field.type == gdb.TYPE_CODE_FUNC or \
        field.type == gdb.TYPE_CODE_VOID or field.type == gdb.TYPE_CODE_METHOD or \
        field.type == gdb.TYPE_CODE_METHODPTR or field.type == None: continue
        key = field.name
        if key is None: continue
        try: state[key]
        except RuntimeError: continue
        val = PF[key]
        if field.is_base_class and len(field.type.fields()) != 0:
            for k, v in process_kids(state, field):
                yield key + " :: " + k, v
        else:
            yield key, val
 
 
def printer(key, val):
    if val.type.code == gdb.TYPE_CODE_PTR or val.type.code == gdb.TYPE_CODE_MEMBERPTR:
        if not val: yield key, "NULL"
        else:
            try:
                str(val.dereference())
                yield key, val.dereference()
            except RuntimeError: 
                yield key, "Cannot access memory at address " + str(val.address)
    elif val.type.code == gdb.TYPE_CODE_INT:
        yield key, int(val)
    elif val.type.code == gdb.TYPE_CODE_FLT or val.type.code == gdb.TYPE_CODE_DECFLOAT:
        yield key, float(val)
    elif val.type.code == gdb.TYPE_CODE_STRING or val.type.code == gdb.TYPE_CODE_ARRAY:
        yield key, str(val)
    else: yield key, val
 
# register the pretty-printer
pretty_printers_dict = {}
pretty_printers_dict[re.compile ('.*Generic.*')] = GenericPrinter
gdb.pretty_printers.append(lookup_function)
```

That's it. We now have generic pretty-printers that we can use for any struct.
Suppose we have this struct:
    
```cpp
struct Generic {
    int a;
    double b;
    vector<int> c;
    int *ptr;
}
```

And we initialize it with a = 0, b = 10, and ptr = pointer to an int with value
50.

Without pretty printers:

```cpp
$4 = {a = 0, b = 10, c = {<std::_Vector_base<int, std::allocator<int> >> = {_M_impl = {<std::allocator<int>> = {<__gnu_cxx::new_allocator<int>> = {<No data fields>}, <No data fields>}, _M_start = 0x0, _M_finish = 0x0, _M_end_of_storage = 0x0}}, <No data fields>}, 
  ptr = 0x7fff5fbffabc}
```

With pretty-printers:

```cpp
$4 = Generic object with the following members: = {
  a = 0,
  b = 10,
  c = std::vector of length 0, capacity 0,
  ptr = 50
}
```

Don't forget, even if you have pretty-printers, you can see the output gdb
would have produced by default using:
    
```cpp
print /r *generic
```
