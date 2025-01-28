# RESTfulCore

So much of building a RESTful client is boilerplate code work. The kind of 
boilerplate that is prone to creating problems later if something is not fully 
implemented. This is the result of our desire to not recreate the wheel every 
time we need to do a RESTful interface. Since we work in both C# and Swift, we 
wanted something that was very similar. This is the Swift implementation of our 
RESTful base.

This base implements both sync and async methods, and was designed to be as 
minimal as possible in both code and expectation, with the complex portions of 
the work being done in the classes that inherit from it. 

For our uses, we subclass RESTObject to create our client entities, and consume 
a connection form there.

There are examples within the unit tests in the Github repository at 
https://github.com/Druware/RESTfulCore

## License

```
MIT License

Copyright (c) 2023-2025 Druware Software Designs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## History

*v.0.14*

* fixed a problem where the List() methods returning arrays no longer work with
 RESTObjects, but only works with primitves ( string, int, etc )
 




