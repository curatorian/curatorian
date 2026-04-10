defmodule CuratorianWeb.Visitor.CheckOutLive do
  @moduledoc "Visitor check-out LiveView — scoped to the logged-in user's node."

  use CuratorianWeb, :live_view

  alias Voile.Schema.System
  alias Voile.Schema.Master

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    node = user.node

    cond do
      is_nil(node) ->
        {:ok,
         socket
         |> put_flash(:error, "Your account is not associated with any node.")
         |> redirect(to: ~p"/")}

      not (is_manager?(user) or is_super_admin?(user) or is_node_admin?(user)) ->
        {:ok,
         socket
         |> put_flash(:error, "You are not authorized to access this page.")
         |> redirect(to: ~p"/")}

      true ->
        locations = Master.list_locations(node_id: node.id, is_active: true)

        {:ok,
         socket
         |> assign(:node, node)
         |> assign(:locations, locations)
         |> assign(:selected_location, nil)
         |> assign(:step, :select_room)
         |> assign(:form, to_form(%{}, as: :checkout))
         |> assign(:survey_form, to_form(%{}, as: :survey))
         |> assign(:checkout_log_id, nil)
         |> assign(:checkout_error, nil)}
    end
  end

  @impl true
  def handle_event("select_location", %{"id" => location_id}, socket) do
    location = Enum.find(socket.assigns.locations, &(to_string(&1.id) == location_id))

    {:noreply,
     socket
     |> assign(:selected_location, location)
     |> assign(:step, :show_form)}
  end

  def handle_event("restore_location", %{"id" => location_id}, socket) do
    location = Enum.find(socket.assigns.locations, &(to_string(&1.id) == to_string(location_id)))

    if location do
      {:noreply,
       socket
       |> assign(:selected_location, location)
       |> assign(:step, :show_form)}
    else
      {:reply, %{error: true}, socket}
    end
  end

  def handle_event("back_to_rooms", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :select_room)
     |> assign(:selected_location, nil)
     |> assign(:form, to_form(%{}, as: :checkout))
     |> assign(:checkout_error, nil)}
  end

  def handle_event("validate", %{"checkout" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :checkout))}
  end

  def handle_event("check_out", %{"checkout" => params}, socket) do
    identifier = String.trim(params["identifier"] || "")
    node = socket.assigns.node
    location = socket.assigns.selected_location

    case process_check_out(identifier, location.id, node.id) do
      {:ok, log} ->
        {:noreply,
         socket
         |> assign(:checkout_log_id, log.id)
         |> assign(:checkout_error, nil)
         |> assign(:step, :show_survey)}

      {:error, :not_found} ->
        {:noreply,
         assign(socket, :checkout_error, "No active check-in found for this identifier today.")}

      {:error, :already_checked_out} ->
        {:noreply, assign(socket, :checkout_error, "This visitor has already checked out today.")}

      {:error, _reason} ->
        {:noreply,
         assign(socket, :checkout_error, "Failed to process check-out. Please try again.")}
    end
  end

  def handle_event("submit_survey", %{"survey" => params}, socket) do
    node = socket.assigns.node
    location = socket.assigns.selected_location

    rating =
      case Integer.parse(params["rating"] || "") do
        {r, _} when r in 1..5 -> r
        _ -> nil
      end

    attrs = %{
      "rating" => rating,
      "comment" => params["comment"],
      "location_id" => location.id,
      "node_id" => node.id,
      "visitor_log_id" => socket.assigns.checkout_log_id,
      "survey_type" => "general"
    }

    case System.create_visitor_survey(attrs) do
      {:ok, _survey} ->
        Process.send_after(self(), :reset_survey, 2_000)
        {:noreply, assign(socket, :step, :done)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:survey_form, to_form(changeset, as: :survey))
         |> put_flash(:error, "Survey save failed. Please fix the errors below.")}
    end
  end

  def handle_event("validate_survey", %{"survey" => params}, socket) do
    {:noreply, assign(socket, :survey_form, to_form(params, as: :survey))}
  end

  def handle_event("skip_survey", _params, socket) do
    next_step = if(socket.assigns.selected_location, do: :show_form, else: :select_room)

    {:noreply,
     socket
     |> assign(:step, next_step)
     |> assign(:form, to_form(%{}, as: :checkout))
     |> assign(:survey_form, to_form(%{}, as: :survey))
     |> assign(:checkout_log_id, nil)
     |> assign(:checkout_error, nil)}
  end

  def handle_event("reset", _params, socket) do
    next_step = if(socket.assigns.selected_location, do: :show_form, else: :select_room)

    {:noreply,
     socket
     |> assign(:step, next_step)
     |> assign(:form, to_form(%{}, as: :checkout))
     |> assign(:survey_form, to_form(%{}, as: :survey))
     |> assign(:checkout_log_id, nil)
     |> assign(:checkout_error, nil)}
  end

  @impl true
  def handle_info(:reset_survey, socket) do
    next_step = if(socket.assigns.selected_location, do: :show_form, else: :select_room)

    {:noreply,
     socket
     |> assign(:step, next_step)
     |> assign(:form, to_form(%{}, as: :checkout))
     |> assign(:survey_form, to_form(%{}, as: :survey))
     |> assign(:checkout_log_id, nil)
     |> assign(:checkout_error, nil)}
  end

  defp process_check_out(identifier, location_id, node_id) do
    today = Date.utc_today()
    start_of_today = DateTime.new!(today, ~T[00:00:00], "Etc/UTC")
    end_of_today = DateTime.new!(today, ~T[23:59:59], "Etc/UTC")

    opts = [
      from_date: start_of_today,
      to_date: end_of_today,
      location_id: location_id,
      node_id: node_id,
      search: identifier,
      limit: 1
    ]

    case System.list_visitor_logs(opts) do
      [log | _] when is_nil(log.check_out_time) ->
        System.update_visitor_log(log, %{"check_out_time" => DateTime.utc_now()})

      [_log | _] ->
        {:error, :already_checked_out}

      [] ->
        {:error, :not_found}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div id="check-out-page" class="min-h-screen bg-base-200 py-12 px-4" phx-hook="PersistLocation" data-storage-key="curatorian:check_out_selected_location_id">
        <div class="max-w-2xl mx-auto">
          <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-base-content">Visitor Check-Out</h1>
            <p class="text-base-content/60 mt-2">{@node.name}</p>
          </div>

          <%!-- Step 1: Select Room --%>
          <%= if @step == :select_room do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <h2 class="card-title text-xl mb-4">Select Room / Location</h2>
                <%= if @locations == [] do %>
                  <div class="alert alert-info">
                    <.icon name="hero-information-circle" class="w-5 h-5" />
                    <span>No active locations found for your node.</span>
                  </div>
                <% else %>
                  <div class="grid grid-cols-1 gap-3 sm:grid-cols-2">
                    <%= for location <- @locations do %>
                      <button
                        phx-click="select_location"
                        phx-value-id={location.id}
                        class="btn btn-outline btn-lg justify-start gap-3 h-auto py-4"
                      >
                        <.icon name="hero-map-pin" class="w-6 h-6 text-primary" />
                        <span class="text-left">{location.location_name}</span>
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%!-- Step 2: Check-Out Form --%>
          <%= if @step == :show_form do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <div class="flex items-center gap-2 mb-6">
                  <button phx-click="back_to_rooms" class="btn btn-ghost btn-sm btn-circle">
                    <.icon name="hero-arrow-left" class="w-5 h-5" />
                  </button>
                  <div>
                    <h2 class="card-title text-xl">Check Out</h2>
                    <p class="text-sm text-base-content/60">{@selected_location.location_name}</p>
                  </div>
                </div>
                <%= if @checkout_error do %>
                  <div class="alert alert-error mb-4">
                    <.icon name="hero-exclamation-circle" class="w-5 h-5" />
                    <span>{@checkout_error}</span>
                  </div>
                <% end %>
                <.form for={@form} id="checkout-form" phx-change="validate" phx-submit="check_out">
                  <div class="space-y-4">
                    <.input
                      field={@form[:identifier]}
                      type="text"
                      label="Visitor ID / NIM / NIP"
                      placeholder="Enter your identifier"
                      required
                    />
                  </div>
                  <div class="card-actions mt-6">
                    <button type="submit" class="btn btn-warning w-full">
                      <.icon name="hero-arrow-left-circle" class="w-5 h-5" /> Check Out
                    </button>
                  </div>
                </.form>
              </div>
            </div>
          <% end %>

          <%!-- Step 3: Survey --%>
          <%= if @step == :show_survey do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body text-center">
                <div class="flex justify-center mb-4">
                  <div class="w-16 h-16 bg-success/20 rounded-full flex items-center justify-center">
                    <.icon name="hero-check-circle" class="w-10 h-10 text-success" />
                  </div>
                </div>
                <h2 class="card-title text-xl justify-center">Check-Out Successful!</h2>
                <p class="text-base-content/60 mb-6">
                  Thank you for visiting. Please share your feedback.
                </p>
                <.form for={@survey_form} id="checkout-survey-form" phx-change="validate_survey" phx-submit="submit_survey">
                  <div class="space-y-4">
                    <div>
                      <label class="label justify-center">
                        <span class="label-text font-medium">Rating (1–5)</span>
                      </label>
                      <div class="flex justify-center gap-3 mt-2">
                        <%= for rating <- 1..5 do %>
                          <% selected = to_string(@survey_form[:rating].value || "") == to_string(rating) %>
                          <label
                            class={[
                              "cursor-pointer flex flex-col items-center gap-1 rounded-2xl border px-4 py-3 transition-all duration-150",
                              selected && "border-primary bg-primary/10 shadow-sm"
                            ]}
                          >
                            <input
                              type="radio"
                              name="survey[rating]"
                              value={rating}
                              checked={selected}
                              class="radio radio-primary"
                            />
                            <span class="text-sm font-medium">{rating}</span>
                          </label>
                        <% end %>
                      </div>
                    </div>
                    <.input
                      field={@survey_form[:comment]}
                      type="textarea"
                      label="Comment (optional)"
                      placeholder="How was your visit today?"
                    />
                  </div>
                  <div class="card-actions mt-6 flex-col gap-2">
                    <button type="submit" class="btn btn-primary w-full">Submit Feedback</button>
                    <button type="button" phx-click="skip_survey" class="btn btn-ghost w-full">
                      Skip
                    </button>
                  </div>
                </.form>
              </div>
            </div>
          <% end %>

          <%!-- Done --%>
          <%= if @step == :done do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body text-center">
                <div class="flex justify-center mb-4">
                  <div class="w-16 h-16 bg-success/20 rounded-full flex items-center justify-center">
                    <.icon name="hero-check-circle" class="w-10 h-10 text-success" />
                  </div>
                </div>
                <h2 class="card-title text-xl justify-center">Thank You!</h2>
                <p class="text-base-content/60">Your check-out has been recorded successfully.</p>
                <div class="card-actions mt-6">
                  <button phx-click="reset" class="btn btn-primary w-full">New Check-Out</button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
