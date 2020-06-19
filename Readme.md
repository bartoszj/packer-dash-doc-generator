Packer Dash Docs Generator
==========================

This projects essence has been taken from [https://github.com/rolandjohann/terraform-dash-doc-generator](https://github.com/rolandjohann/terraform-dash-doc-generator) and updated to generate Packer docs.

### Installation

```bash
rbenv install 2.5.3
gem install -N bundler
bundle install
```

### Build

To build execute command:

```bash
./build.sh <version>
```

Then move the docset into a proper directory.

### Issues

In case of error:

```
Error occurred prerendering page "/downloads". Read more: https://err.sh/next.js/prerender-error
TypeError: Cannot read property 'builds' of undefined
```

Download the newest version of the `website/pages/downloads/index.jsx` file.
