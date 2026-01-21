export default {
  mounted() {
    this.el.addEventListener("input", (event) => {
      const titleValue = event.target.value;

      const slugValue = titleValue
        .toLowerCase() // Convert to lowercase
        // .trim() // Remove whitespace from both ends
        .replace(/[\s]+/g, "-") // Replace spaces with hyphens
        .replace(/[^\w\-]+/g, "") // Remove all non-word chars
        .replace(/\-\-+/g, "-"); // Replace multiple hyphens with a single hyphen

      const slugInput = document.getElementById("slug");
      slugInput.value = slugValue;
    });
  },
};
