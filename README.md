Rails 3.2/4.0 Integration for Jquery UI NestedSortableTree Plugin
=================================================================

The `nestedsortabletree-rails` gem integrates the [Jquery UI Nested Sortable Tree](http://leifcr.github.com/nestedSortableTree) plugin with the Rails 3.2 and 4.0 asset pipeline.


Instructions
------------

**1. Add `nestedsortabletree-rails` to your Gemfile**

    gem 'nestedsortabletree-rails'

**2. Run `bundle install`.**


**3. Using**

Add to your application.js:
_JQuery_ and _JqueryUI_ is only needed if you haven't included them already

    //= require jquery 
    //= require jquery.ui.all
    //= require jquery.ui.nestedSortableTree

I recommend using [jquery-rails](https://github.com/indirect/jquery-rails) and [jquery-ui-rails](https://github.com/joliss/jquery-ui-rails)

Other jquery implementations should do fine as well.

See http://leifcr.github.com/nestedSortableTree for usage.

Credits
-------

[Didier Laffourgue](https://github.com/did) for the [aloha-rails plugin](https://github.com/locomotivecms/aloha-rails) as a blueprint. See further credits in the readme on aloha-rails plugin.

Contact
-------

Feel free to contact me at @leifcr (twitter).

Copyright (c) 2012-2013 Leif Ringstad