import selectize from "selectize";

// Right now we're using selectize.js (https://selectize.github.io/selectize.js/) to make our select boxes fancy.
// This could be changed to some other library at some point - this makes it possible for us to abstract that away.
// Just add the `unfancy` and `fancy-select` classes to a select box and it will be a fancy select box!
const LoadFancySelects = () => {
  $(".unfancy.fancy-select.create-options-add select").selectize({
    create: true,
    plugins: ["remove_button"],
  });

  // The "add item" text says search to make it clearer
  $(".unfancy.fancy-select.create-options-search select").selectize({
    create: true,
    plugins: ["remove_button"],
    render: {
      option_create: function(data, escape) {
        return `<div class="create">Search for <strong>${escape(
          data.input
        )}</strong>&hellip;</div>`;
      },
    },
  });

  $(".unfancy.fancy-select.no-restore-on-backspace select").selectize({
    create: false,
    plugins: ["remove_button"],
  });
  // Remove, because we've already added them
  $(".unfancy.fancy-select.no-restore-on-backspace").removeClass("unfancy");

  $(".unfancy.fancy-select select").selectize({
    create: false,
    plugins: ["restore_on_backspace"],
  });
  // Remove them so we don't initialize twice
  $(".unfancy.fancy-select").removeClass("unfancy");

  // Turbolinks addition h/t https://gist.github.com/simonini/c237df3770b223acf3c3de6c3cd38226
  document.addEventListener("turbolinks:load", function() {
    $(".selectize").selectize();
    // With turbolinks, selectize placeholder text gets broken
    $(".selectize-control .not-full input").css("width", "100%");
  });

  document.addEventListener("turbolinks:before-cache", function() {
    $(".selectize").each(function() {
      if (this.selectize != undefined) {
        this.selectize.destroy();
      }
    });
  });
};

export default LoadFancySelects;
