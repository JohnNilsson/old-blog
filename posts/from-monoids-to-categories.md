---
title: From Monoids to Categories
date: '2011-07-03'
tags: [math, category theory, scala]
encoding: utf-8
---

Monoid is the mathematical name for some of the interesting properties shared by operations such as addition and multiplication. More precisely it is defined as three things:

1. A set of objects
2. An associative operation on those object.
3. An identity object for that operation

Or a Monoid is a triple $(M,\centerdot,e)$ such that
$$\forall x,y,z \in M$$
$$(x \centerdot y) \centerdot z = x \centerdot (y \centerdot z)$$
$$e \centerdot x = x = x \centerdot e$$

In Scala we can encode this as
<pre class="brush: scala">
    class Monoid[T](id: T, op: (T, T) => T)
</pre>

Typical monoids most of us are familiar with are addition and multiplication with their respective identity $(\mathbb{R},+,0)$ and $(\mathbb{R},\times,1)$. These examples happens to also be commutative but this is not a requirement for monads. As an example of a non-commutative monad consider string concatenation.

The reason we think these are interesting properties is because it makes life easier for us in various ways. The fact that the operation is closed over the set means that no matter how we combine objects using this operator we will always end up with an object that can be further combined. This is tremendously helpful in all types of applications where composition is useful, for example in programming.

Associativity lets us forget evaluation order, also very useful for programs. Not only for making programs easier to reason about but also because it allows us pick a suitable evaluation strategy without worrying about semantics. We can even evaluate things in parallel if we think it will help us.

And finally the identity gives us a way out of corner cases in various situations. For example when implementing a generic sum in Scala the identity can be used when summing the empty Seq.

<pre class="brush: scala">
    def sum[T](elems: Seq[T])(implicit m: Monoid[T]) =
      elems.fold(m.id)(m.op)
</pre>


Monoids as categories
---------------------

A Category is in essence very similar to a Monoid. Both captures the notion of associative composition with an identity. The difference is that a category generlizes and abstracts the concept even further.

In the Monoid above we defined the associative operation as closed over the set. This property made life easy because it meant that any two object can be combined using the operator. In a category this is no longer the case. In fact we drop even the notion of a set and just assume that we have things, called morphisms, that may, or may not, be combined with eachother.

Just as before we don't assume that composition is commutative, just that it is associative. In fact, we don't even assume that reversing the operands would
be a valid composition at all.

To capture this we model morphisms as having two ends, the domain and codomain. A morphism $f$ with domain $A$ and codomain $B$ ($f:A\rightarrow B$) can be composed with other morphisms if they have domain $B$ or codomain $A$.

We also split the notion of identity into left, and right identity respectively.

The category laws can thus be expressed as:
  $$\forall f:A\rightarrow B,g:B\rightarrow C,h:C\rightarrow D$$
  $$(f \circ g) \circ h = f \circ (g \circ h)$$
  $$1\_A \circ f = f = f \circ 1\_B$$

<aside>I'm using $\circ$ in what's called <dfn>diagrammatic order</dfn> here because I think it makes more sense, math texts usually put it the other way around though.</aside>

Let's see if we can encode this in Scala:
<pre class="brush: scala">
    trait Category {
      type →[_,_]

      def id[A]: A → A
      def compose[A, B, C]: (A → B, B → C) ⇒ A → C
    }
</pre>

To construct a category out of our monoid definition above we can take the set to be an object of the category, and its members be <dfn title="A fancy word for a morphism with the same domain and codomain.">endomorphisms</dfn> on this object. In fact all objects in a category forms monoids in this sense.

<pre class="brush: scala">
    class Monoid[T](id: T, op: (T, T) ⇒ T) extends Category {
      type →[A,B] = T
      def id[A] = id
      def compose[A, B, C] = op
    }
</pre>
<aside>
Btw, the fact that higher kinded types, like $\rightarrow\[A,B\]$ above, can return any type is kind of interesting. Having damanged my brain from to much Java I assumed for a long time that a higher kinded types only abstracted over parameterized classes with the same arity. They do not though, they are just type level functions, free to return what ever they want, similar in spirtit to value level functions.</aside>
