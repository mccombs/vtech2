---
title: "JavaScript Question Zero"
type: "post"
date: 2021-03-12T09:40:21-06:00
subtitle: "How are numbers stored?"
image: ""
tags: ["JavaScript", "question"]
authors: ["nolanaguirre"]
draft: false
---

What does .1 + .2 equal?

Easy math problem, the answer is .3 no problem, right?

Well, not quite. In the magical land of JavaScript, .1 + .2 = 0.30000000000000004, because obviously. This was actually the first thing I learned about JavaScript, my first intro to the language being a lengthy conversation about all the worst things in the language (**glances at the _this_ keyword**).

But, back to math... why doesn't .1 + .2 = .3 in JavaScript? Or, more importantly, *how are numbers stored in JavaScript?* I thought that this would be a simple question, but it seems very few people know the answer. In fact, the only correct answer to this question received during an interview was "IEEE 754 standard Floating point", which is a bit much.

A simpler answer is: floats. In JavaScript, numbers are stored as floats.

Now, for most applications this might not be too big of a deal. If you don't have to do lots of math in JavaScript, you might never run into this *feature*. With Vertalo being a FinTech company, however, numbers are very, very important, so we choose to make this our first interview question for anyone claiming to know JavaScript; that is until no one got it right.

After this we realized that perhaps this might be too tough of a question to be the first, and thus "How are numbers stored in JavaScript?" became JavaScript Question Zero.

What does it mean to be question zero though? Nothing of course, it's just a joke, but it is rather concerning. I'd urge all those who do not know the inner workings of JavaScript including the event loop, promises, data types and how objects work as a whole to look into it; it will lead you to have a much firmer grasp of the language.

### Questions

For those interested, a few more questions are below. If you know the answer to them, congratulations! They aren't as trivial to answer as you might've thought:

* What is the functional difference between `{...foo, ...bar}` and `{...bar, ...foo}`? Assume foo and bar are objects.

* What is the difference between `const foo = Object.create(null)` and `const foo = {}`?

* What is the relationship between `a` and `b` in this code:

```
const foo = (x) => {
  const F = function() {}
  F.prototype = x
  return new F()
}
const b = foo(a)
```
