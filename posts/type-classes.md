---
title: Type classes for C# programmers
description: An introduction to polymorphism by type class aimed at C# programmers
date: '2012-08-15'
tags: [code, c#, type classes]
encoding: utf-8
---

Rich Hickey [talked][simple1] [about][simple2] ways to avoid complexity in programming. One of the
the approaches he emphasized was to utilize polymorphism à la carte, which is a reference to a Clojure
feature called [protocols][] designed to address the [expression problem]. He compared this technique to
type classes, as a similar feature found in other languages.

[simple1]: http://www.infoq.com/presentations/Simple-Made-Easy "Simple Made Easy, Strange Loop 2011"
[simple2]: http://www.infoq.com/presentations/Simple-Made-Easy-QCon-London-2012 "Simple Made Easy, QCon 2012"
[protocols]: http://clojure.org/protocols "Clojure Protocols"
[expression problem]: http://c2.com/cgi/wiki?ExpressionProblem "The Expression Problem"

Type classes was initially introduced in Haskell and has later been adopted by Scala in the form of
implicit parameters. Presumably users of those languages will be exposed to the benefits they bring in
some form or other and traced it to this construct. Those who are stuck with a less capable language,
like C#, run a slightly lower chance of running in to them and realize what they are though.

This is my attempt to illustrate the concept of type classes for you, and how, to the extent possible
in C#, they can be used in day to day design of programs.


The Expressed Problem
---------------------
Let us first of all start with an interesting problem to serve as our guide. Lets take something
straight forward like: Implement a sum-operation, it should take collection of values and return
the result of adding them all together.

$$f(S) = \displaystyle\sum_{x \in S} x$$


The monomorphic approach
------------------------
We could try to implement this by simple case analysis like so:

```c#
public static object Sum(this IEnumerable vals, object zero) {
    if (zero is int) {
        int sum = (int)zero;
        foreach (int i in (IEnumerable<int>)vals)
            sum += i;
        return sum;
    }
    throw new NotImplementedException();
}
```

One major problem with this approach is that we have to edit and recompile
this code each time someone would like to support another case for an addable
type. Which is precisely what the expression problem is all about.

It also suffers from lack of type safety. Invoking this code will compile
even if the type we are trying to sum isn't supported.


Ad-hoc polymorphism
-------------------
When the case analysis only dispatches on type we can simply use overloading
to implement the different cases, so called ad-hoc polymorphism.

```c#
public static int Sum(this IEnumerable<int> ints) {
    var sum = 0;
    foreach (var i in ints)
        sum += i;
    return sum;
}

public static string Sum(this IEnumerable<string> strings) {
    var sum = string.Empty;
    foreach (var s in strings)
        sum += s;
    return sum;
}
```
Now anyone can add cases by simply implementing Sum for their type.
As a nice side-effect we can also let the implementation dictate
the zero case.

However, as you can see, the code is basically copied for each type.
As good programmers our instinct is to generalize the algorithm for
all supported types to remove this blatant violation of the DRY principle.
One problem we must overcome first is that our add-operation is just
as ad-hoc as our sum-operation.


Subtype polymorphism
--------------------
Lets apply the standard OOP-solution, subtype polymorphism, to fix
this:

```c#
public interface Addable
{
    Addable Add(Addable addend);
}

// To support the empty case we have to ask the caller to supply the zero value.
public static Addable Sum(this IEnumerable<Addable> summables, Addable zero) {
    var sum = zero;
    foreach (var s in summables)
        sum = sum.Add(s);
    return sum;
}
```

Adding cases is still possible by simply implementing Addable. Unfortunately we can't
actually do this for types we can't control, like int and string. Which is the other
side of the expression problem.

Unfortunately we are also now back not knowing what to do with the zero-case.

This particular implementation also suffers from a type safety issue where each
Add-implementation must check for compatible types at run-time.

Parametric Subtype Polymorphism
-------------------------------

We can fix this with type parameters, which I'll include here just so you can stop thinking
about it.

```c#
public interface Addable<ThisType> where ThisType : Addable<ThisType>  
{
    ThisType Add(ThisType addend);
}

public static T Sum<T>(this IEnumerable<T> summables, T zero) where T : Addable<T> {
    var sum = zero;
    foreach (var s in summables)
        sum = sum.Add(s);
    return sum;
}
```

We still need to fix the bigger issue of how to add cases for types we can't
edit though.


Parametric Polymorphism
-----------------------

To resolve the situation we could abandon the Addable abstraction and rely
entirely on parametric polymorphism where we ask the caller supply us both with
the zero case and the add-operation.

```c#
public static T Sum<T>(this IEnumerable<T> summables, T zero, Func<T, T, T> add)
{
    var sum = zero;
    foreach (var s in summables)
        sum = add(sum, s);
    return sum;
}

// In fact, this operation is already provided by LINQ
public static T LINQSum<T>(this IEnumerable<T> summables, T zero, Func<T, T, T> add)
{
    return summables.Aggregate(zero, add);
}
```
Now we can sum anything that someone could provide a zero and an add operation for and
neither our Sum-operation or any types needs to change to support new cases.

The problem is that we've put the responsibility of verifying the contract of the
add-operation on to the caller of our Sum-operation. Not a very nice thing to do.


The Monoid
----------

We would like to declare the contract
which our Sum-operation depends on, and we would like implementations of this contract
to be available to our poor API-user.

<p>Our contract stipulates the relationship between add and zero like so:
$$\forall x, y, z \in \mathrm{T} \begin{cases}
    \mathrm{add}(\mathrm{zero}, x) = x, & \text{Left identity} \\
    \mathrm{add}(x, \mathrm{zero}) = x, & \text{Right identity} \\
    \mathrm{add}(\mathrm{add}(x, y), z) = \mathrm{add}(x, \mathrm{add}(y, z)), & \text{Associative}
\end{cases}$$</p>

In fact there is a concept like this in abstract algebra called a Monoid.

```c#
public sealed class Monoid<T> : TypeClass
{
    public readonly T Zero;
    public readonly Func<T, T, T> Add;

    public Monoid(T zero, Func<T, T, T> add) {
        Law("Left identity",    (T x) => add(zero, x).Equals(x));
        Law("Right identity",   (T x) => add(x, zero).Equals(x));
        Law("Associative",      (T x, T y, T z) =>
            add(add(x, y), z).Equals(add(x, add(y, z))));

        this.Zero = zero;
        this.Add = add;
    }

}
```

Given this contract we can use it as a dependency for our Sum:

```c#
public static T Sum<T>(this IEnumerable<T> summables, Monoid<T> mon) {
    return summables.Aggregate(mon.Zero, mon.Add);
}
```

Type Classes
------------

Now we have a fully generic sum operation where the contract
for being summable is extracted into the Monoid type class.

Adding new cases requires no recompilation of either types
or the Sum-implementation. While still requesting a monoid
from the API-user, we are certain that it conforms to our
contract, and it's possible for anyone to provide usable
implementations to the user.

In languages with first class support for type classes (like
Haskell and Scala) type class instances are provided implicitly
by the compiler making the invocation of the operation look like
ordinary ad-hoc polymorphism.

In C# we have no such luxury at compile time, but could use
dependency injection to provide a similar service at runtime.

```c#
public static T Sum<T>(this IEnumerable<T> ts) {
    var mon = ObjectFactory.GetInstance<Monoid<T>>();
    return ts.Aggregate(mon.Zero, mon.Add);
}
```

A slightly more verbose approach is to revert back to the original
ad-hoc polymorphism. But this time we can reuse all parts of the code.
We could even generate this code using a T4 template.

```c#
public static readonly Monoid<int> INT_ADDITION_MONOID =
    new Monoid<int>(0, (x, y) => x + y);

public static int Sum(this IEnumerable<int> vals) {
    return vals.Sum(INT_ADDITION_MONOID);
}

public static readonly Monoid<string> STRING_MONOID =
    new Monoid<string>(string.Empty, string.Concat);

public static string Sum(this IEnumerable<string> vals) {
    return vals.Sum(STRING_MONOID);
}
```
