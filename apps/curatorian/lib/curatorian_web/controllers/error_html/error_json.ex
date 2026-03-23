defmodule CuratorianWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """

  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def render("401.json", _assigns),
    do: %{errors: %{code: 401, title: "Unauthorized", detail: "Authentication required."}}

  def render("403.json", _assigns),
    do: %{
      errors: %{
        code: 403,
        title: "Forbidden",
        detail: "You do not have permission to access this resource."
      }
    }

  def render("404.json", _assigns),
    do: %{
      errors: %{
        code: 404,
        title: "Not Found",
        detail: "The requested resource could not be found."
      }
    }

  def render("400.json", _assigns),
    do: %{
      errors: %{
        code: 400,
        title: "Bad Request",
        detail: "The request was invalid or cannot be processed."
      }
    }

  def render("422.json", assigns) do
    # If the controller passed validation errors in assigns, include them
    detail =
      Map.get(assigns, :errors, Phoenix.Controller.status_message_from_template("422.json"))

    %{errors: %{code: 422, title: "Unprocessable Entity", detail: detail}}
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
