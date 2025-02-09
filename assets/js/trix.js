export default {
  mounted() {
    const element = document.querySelector("trix-editor");

    function uploadFile(file, progressCallback, successCallback) {
      const formData = createFormData(file);
      const csrfToken = document
        .querySelector("meta[name=csrf-token]")
        .getAttribute("content");

      xhr.open("POST", "/trix-uploads", true);
      xhr.setRequestHeader("X-CSRF-Token", csrfToken);

      xhr.upload.addEventListener("progress", function (event) {
        if (event.lengthComputable) {
          const progress = (event.loaded / event.total) * 100;
          progressCallback(progress);
        }
      });

      xhr.addEventListener("load", function (event) {
        if (xhr.status === 201) {
          const url = xhr.responseText;
          const attributes = {
            url,
            href: `${url}?content-disposition=attachment`,
          };
          successCallback(attributes);
        }
      });

      xhr.send(formData);
    }

    function uploadFileAttachment(attachment) {
      uploadFile(attachment.file, setProgress, setAttributes);

      function setProgress(progress) {
        attachment.setUploadProgress(progress);
      }

      function setAttributes(attributes) {
        attachment.setAttributes(attributes);
      }
    }

    function removeFileAttachment(url) {
      const xhr = new XMLHttpRequest();
      const formData = new FormData();
      formData.append("key", url);
      const csrfToken = document
        .querySelector("meta[name='csrf-token']")
        .getAttribute("content");

      xhr.open("DELETE", "/trix-uploads", true);
      xhr.setRequestHeader("X-CSRF-Token", csrfToken);

      xhr.send(formData);
    }

    element.editor.element.addEventListener("trix-change", (e) => {
      this.el.dispatchEvent(new Event("change", { bubbles: true }));
    });

    // Handles behavior when inserting a file
    element.editor.element.addEventListener(
      "trix-attachment-add",
      function (event) {
        if (event.attachment.file) uploadFileAttachment(event.attachment);
      }
    );

    // Handle behavior when deleting a file
    element.editor.element.addEventListener(
      "trix-attachment-remove",
      function (event) {
        removeFileAttachment(event.attachment.attachment.previewURL);
      }
    );
  },
};
