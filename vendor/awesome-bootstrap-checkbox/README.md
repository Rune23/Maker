Awesome Bootstrap Checkbox
==========================

Font Awesome Bootstrap Checkboxes &amp; Radios plugin. Pure css way to make inputs look prettier. **No javascript**!

**[Demo](http://awesome-bootstrap-checkbox.okendoken.com/demo/index.html)**


Repository moved. Update your urls!
------------

We have transferred Awesome Bootstrap Checkbox to a new location under our organization account - https://github.com/flatlogic/awesome-bootstrap-checkbox. Though Gihub provides
redirects from old urls, we strongly recommend updating any existing local clones to point to the new repository URL. You can
do this by using `git remote` on the command line:

````bash
git remote set-url origin https://github.com/flatlogic/awesome-bootstrap-checkbox.git
````

Use
------------

First just include **awesome-bootstrap-checkbox.css** somewhere in your html. Or **awesome-bootstrap-checkbox.scss** if you use sass.
Next everything is based on code convention. Here is checkbox markup from Bootstrap site:

````html
<form role="form">
  ...
  <div class="checkbox">
    <label>
      <input type="checkbox"> Check me out
    </label>
  </div>
  ...
</form>
````

We have to alter it a bit:
````html
<form role="form">
  ...
  <div class="checkbox">
    <input type="checkbox" id="checkbox1">
    <label for="checkbox1">
        Check me out
    </label>
  </div>
  ...
</form>
````
That's it. It will work. But it **will not** work if you nest input inside label or put label before input.

Radios
------------

It's the same for radios. Markup has to be the following:
````html
<form role="form">
  ...
  <div class="radio">
      <input type="radio" name="radio2" id="radio3" value="option1">
      <label for="radio3">
          One
      </label>
  </div>
  <div class="radio">
      <input type="radio" name="radio2" id="radio4" value="option2" checked>
      <label for="radio4">
          Two
      </label>
  </div>
  ...
</form>
````

Brand Colors and other features
------------

You may use `checkbox-primary`, `checkbox-danger`, `radio-info`, etc to style checkboxes and radios with brand bootstrap colors.

`checkbox-circle` is for rounded checkboxes.

`checkbox-single` and `radio-single` for inputs without label text.

Glyphicons way (Opt-out Font Awesome)
------------

If you want to use glyphicons instead of font-awesome then override `.checkbox` class:
````css
.checkbox input[type=checkbox]:checked + label:after {
    font-family: 'Glyphicons Halflings';
    content: "\e013";
}
.checkbox label:after {
    padding-left: 4px;
    padding-top: 2px;
    font-size: 9px;
}
````

Credits
------------

Based on [Official Bootstrap Sass port](https://github.com/twbs/bootstrap-sass) and awesome [Font Awesome](https://github.com/FortAwesome/Font-Awesome).