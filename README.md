# JavaScript Scope Inspector for Atom

View your JavaScript code from a different perspective. Explore nested scopes and detect variable shadowing and hoisting.

**Makes use of the new Decorations API. Please upgrade your Atom and make sure to enable the [React editor view](http://blog.atom.io/2014/07/02/moving-atom-to-react.html).**

![Scope Inspector](https://raw.githubusercontent.com/tvooo/scope-inspector/master/scope-inspector.gif)

## This is heavy work-in-progress stuff

**If you've installed after 20 July 2014, some metrics are tracked BY DEFAULT. If you want to disable this, see below.**

I'm working on this as part of my Master's thesis project in Interaction Design.

Don't expect it to work perfectly, especially when it comes to parsing and analyzing the scope. This is a proof-of-concept. Please report any bugs and suggestions.

## Install

`$ apm install scope-inspector`

## Default keyboard shortcuts

`ctrl+alt+i` toggles the sidebar

## Metrics & feedback

From 20 July 2014, this is **enabled** by default.

Scope Inspector is a project I'm doing for my thesis in Interaction Design. For my research, I would like to track some usage metrics. *Please keep tracking enabled in the package's settings view*, it will help my work a great deal.

Additionally, I am happy for any qualitative feedback I get. If you're willing to participate in an interview, please send me [an email](mailto:tim@tvooo.de).

Here's what is going to be tracked:

* Your, userId which is a hash generated through your MAC address. Same as what [Atom's Metrics package](https://github.com/atom/metrics/) does.
* Plugin is enabled/disabled
* Sidebar is toggled
* Breadcrumbs are toggled
* Highlighting is toggled
* Hoisting Indication is toggled
* Breadcrumb is hovered (scope highlight)
* Breadcrumb is clicked (navigate to surrounding scope)

### How to disable tracking

Open the Settings View, navigate to the "Scope Inspector" package and remove the checkmark before "Track Usage Metrics".

## Features

*"Current scope"* - the scope that your cursor is placed in :)

### Inline

#### Highlight current scope

![Highlight current scope](https://raw.githubusercontent.com/tvooo/scope-inspector/master/scope-highlight.png)

#### Indicate hoisted variables

![Indicate hoisted variables](https://raw.githubusercontent.com/tvooo/scope-inspector/master/hoisting.png)

### Breadcrumbs (bottom bar)

- Show scope nesting
- Navigate the scope-ladder upwards
- Highlight surrounding scopes

### Sidebar

![Sidebar](https://raw.githubusercontent.com/tvooo/scope-inspector/master/sidebar.png)

List parameters, variables and nested functions of the current and all surrounding scopes (closest is on top, furthest [global scope] on the bottom)

#### Indicate if an identifier will be hoisted  

![Hosting indicator](https://raw.githubusercontent.com/tvooo/scope-inspector/master/hoisted.png)

#### Indicate if an identifier shadows another identifier (with the same name, in a surrounding scope)  

![Shadowing](https://raw.githubusercontent.com/tvooo/scope-inspector/master/shadowing.png)

#### Indicate if an identifier is shadowed  

![Shadowed](https://raw.githubusercontent.com/tvooo/scope-inspector/master/shadowed.png)
