defmodule CuratorianWeb.LogoutConfirmHTML do
  @moduledoc """
  Template for the cross-app logout confirmation interstitial.
  """

  use CuratorianWeb, :html

  embed_templates "logout_confirm_html/*"
end
