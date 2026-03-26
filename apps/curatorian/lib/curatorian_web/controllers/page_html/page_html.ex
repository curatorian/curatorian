defmodule CuratorianWeb.PageHTML do
  use CuratorianWeb, :html
  import CuratorianWeb.HomepageComponents

  # Use single-level templates in page_html root
  embed_templates "*"
end
