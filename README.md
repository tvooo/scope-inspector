# JavaScript Scope Inspector for Atom

View your JavaScript code from a different perspective. Explore nested scopes and detect variable shadowing, hoisting, and closures.

## This is heavy alpha work-in-progress stuff

I'm working on this as part of my Master's thesis project in Interaction Design.

Don't expect it to work perfectly, especially when it comes to parsing and analyzing the scope. This is a proof-of-concept.

## Install

It's not on apm yet, so clone the repository into your `~/.atom/packages/` folder and be merry.

## What's it do?

JavaScript works with lexical scoping, so we can get most of the relevant information out with static analysis alone (i.e. we don't need to hook into it at runtime)!

* Inspect the scope that your cursor is placed on
  * List available identifiers in the current scope
  * List identifiers in all the parent scopes, up to global
  * See how identifiers were created
* See when identifiers are shadowed
* See when variable declarations are hoisted
* Visually mark scopes in the editor
