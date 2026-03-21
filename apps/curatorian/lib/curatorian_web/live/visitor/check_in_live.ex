defmodule CuratorianWeb.Visitor.CheckInLive do
  @moduledoc "Visitor check-in LiveView — scoped to the logged-in user's node."

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

      not (is_manager?(user) or is_super_admin?(user)) ->
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
         |> assign(:form, to_form(%{}, as: :visitor))
         |> assign(:survey_form, to_form(%{}, as: :survey))
         |> assign(:checkin_log_id, nil)}
    end
  end

  @impl true
  def handle_event("select_location", %{"id" => location_id}, socket) do
    location = Enum.find(socket.assigns.locations, &(to_string(&1.id) == location_id))

    {:noreply,
     socket
     |> assign(:selected_location, location)
     |> assign(:step, :show_forms)}
  end

  def handle_event("back_to_rooms", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :select_room)
     |> assign(:selected_location, nil)
     |> assign(:form, to_form(%{}, as: :visitor))}
  end

  def handle_event("validate", %{"visitor" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :visitor))}
  end

  def handle_event("check_in", %{"visitor" => params}, socket) do
    node = socket.assigns.node
    location = socket.assigns.selected_location

    attrs = %{
      "visitor_identifier" => String.trim(params["identifier"] || ""),
      "visitor_name" => String.trim(params["name"] || ""),
      "visitor_origin" => String.trim(params["origin"] || ""),
      "check_in_time" => DateTime.utc_now(),
      "location_id" => location.id,
      "node_id" => node.id,
      "additional_data" => %{
        "visit_purpose" => params["visit_purpose"],
        "gender" => params["gender"]
      }
    }

    case System.create_visitor_log(attrs) do
      {:ok, log} ->
        {:noreply,
         socket
         |> assign(:checkin_log_id, log.id)
         |> assign(:step, :show_survey)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset, as: :visitor))
         |> put_flash(:error, "Check-in failed. Please correct the errors below.")}
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
      "visitor_log_id" => socket.assigns.checkin_log_id,
      "survey_type" => "checkin"
    }

    System.create_visitor_survey(attrs)

    {:noreply, assign(socket, :step, :done)}
  end

  def handle_event("skip_survey", _params, socket) do
    {:noreply, assign(socket, :step, :done)}
  end

  def handle_event("reset", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :select_room)
     |> assign(:selected_location, nil)
     |> assign(:form, to_form(%{}, as: :visitor))
     |> assign(:survey_form, to_form(%{}, as: :survey))
     |> assign(:checkin_log_id, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-base-200 py-12 px-4">
        <div class="max-w-2xl mx-auto">
          <div class="text-center mb-8">
            <h1 class="text-3xl font-bold text-base-content">Visitor Check-In</h1>
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
                        <span class="text-left">{location.name}</span>
                      </button>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <%!-- Step 2: Check-In Form --%>
          <%= if @step == :show_forms do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body">
                <div class="flex items-center gap-2 mb-6">
                  <button phx-click="back_to_rooms" class="btn btn-ghost btn-sm btn-circle">
                    <.icon name="hero-arrow-left" class="w-5 h-5" />
                  </button>
                  <div>
                    <h2 class="card-title text-xl">Visitor Information</h2>
                    <p class="text-sm text-base-content/60">{@selected_location.name}</p>
                  </div>
                </div>
                <.form for={@form} id="checkin-form" phx-change="validate" phx-submit="check_in">
                  <div class="space-y-4">
                    <.input
                      field={@form[:identifier]}
                      type="text"
                      label="Visitor ID / NIM / NIP"
                      placeholder="Enter visitor identifier"
                      required
                    />
                    <.input
                      field={@form[:name]}
                      type="text"
                      label="Full Name"
                      placeholder="Visitor full name"
                      required
                    />
                    <.input
                      field={@form[:origin]}
                      type="text"
                      label="Origin / Department"
                      placeholder="e.g. Faculty of Engineering"
                    />
                    <.input
                      field={@form[:visit_purpose]}
                      type="textarea"
                      label="Purpose of Visit"
                      placeholder="Brief description of visit purpose"
                    />
                    <.input
                      field={@form[:gender]}
                      type="select"
                      label="Gender"
                      options={[{"Select gender", ""}, {"Male", "male"}, {"Female", "female"}]}
                    />
                  </div>
                  <div class="card-actions mt-6">
                    <button type="submit" class="btn btn-primary w-full">
                      <.icon name="hero-arrow-right-circle" class="w-5 h-5" /> Check In
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
                <h2 class="card-title text-xl justify-center">Check-In Successful!</h2>
                <p class="text-base-content/60 mb-6">
                  Take a moment to rate your check-in experience.
                </p>
                <.form for={@survey_form} id="checkin-survey-form" phx-submit="submit_survey">
                  <div class="space-y-4">
                    <div>
                      <label class="label justify-center">
                        <span class="label-text font-medium">Rating (1–5)</span>
                      </label>
                      <div class="flex justify-center gap-3 mt-2">
                        <%= for rating <- 1..5 do %>
                          <label class="cursor-pointer flex flex-col items-center gap-1">
                            <input
                              type="radio"
                              name="survey[rating]"
                              value={rating}
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
                      placeholder="Any feedback or suggestions?"
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
                <h2 class="card-title text-xl justify-center">All Done!</h2>
                <p class="text-base-content/60">Your visit has been recorded successfully.</p>
                <div class="card-actions mt-6">
                  <button phx-click="reset" class="btn btn-primary w-full">New Check-In</button>
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
