// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
import 'bootstrap/dist/js/bootstrap'

// For now, we aren't doing activestorage or channels, so ignore
// require("@rails/activestorage").start();
// require("channels");

// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

// This is where all the actual JS is.
import '../scripts/main'

require('@rails/ujs').start()
require('turbolinks').start()

// Because it's nice to be able to access jQuery in the console, attach it ;)
window.$ = window.jQuery = jQuery
