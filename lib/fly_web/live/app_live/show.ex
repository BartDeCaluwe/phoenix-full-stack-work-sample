defmodule FlyWeb.AppLive.Show do
  use FlyWeb, :live_view
  require Logger

  alias Fly.Client
  alias FlyWeb.Components.HeaderBreadcrumbs

  @default_refresh_rate 5000

  @impl true
  def mount(%{"name" => name}, session, socket) do
    socket =
      assign(socket,
        config: client_config(session),
        state: :loading,
        app: nil,
        app_name: name,
        count: 0,
        authenticated: true,
        appstatus: nil
      )

    # Only make the API call if the websocket is setup. Not on initial render.
    if connected?(socket) do
      schedule_app_status_refresh(0)

      {:ok,
       socket
       |> fetch_app()}
    else
      {:ok, socket}
    end
  end

  defp client_config(session) do
    Fly.Client.config(access_token: session["auth_token"] || System.get_env("FLYIO_ACCESS_TOKEN"))
  end

  defp fetch_app(socket) do
    app_name = socket.assigns.app_name

    case Client.fetch_app(app_name, socket.assigns.config) do
      {:ok, app} ->
        assign(socket, :app, app)

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        Logger.error("Failed to load app '#{inspect(app_name)}'. Reason: #{inspect(reason)}")

        put_flash(socket, :error, reason)
    end
  end

  defp fetch_app_status(socket) do
    app_name = socket.assigns.app_name

    case Client.fetch_app_status(app_name, socket.assigns.config) do
      {:ok, appstatus} ->
        socket
        |> assign(:appstatus, appstatus)
        |> assign(:appstatusUpdatedAt, DateTime.utc_now())

      {:error, :unauthorized} ->
        put_flash(socket, :error, "Not authenticated")

      {:error, reason} ->
        Logger.error(
          "Failed to load app status '#{inspect(app_name)}' status. Reason: #{inspect(reason)}"
        )

        put_flash(socket, :error, reason)
    end
  end

  defp schedule_app_status_refresh(seconds \\ @default_refresh_rate) do
    Process.send_after(self(), :refresh_app_status, seconds)
  end

  @impl true
  def handle_info(:refresh_app_status, socket) do
    socket = fetch_app_status(socket)
    schedule_app_status_refresh()
    {:noreply, socket}
  end

  @impl true
  def handle_event("click", _params, socket) do
    {:noreply, assign(socket, count: socket.assigns.count + 1)}
  end

  def status_bg_color(app) do
    case app["status"] do
      "running" -> "bg-green-100"
      "dead" -> "bg-red-100"
      _ -> "bg-yellow-100"
    end
  end

  def status_text_color(app) do
    case app["status"] do
      "running" -> "text-green-800"
      "dead" -> "text-red-800"
      _ -> "text-yellow-800"
    end
  end

  def deployment_status_bg_color(appstatus) do
    case appstatus["deploymentStatus"]["status"] do
      "successful" -> "bg-green-100"
      "running" -> "bg-blue-100"
      _ -> "bg-yellow-100"
    end
  end

  def deployment_status_text_color(appstatus) do
    case appstatus["deploymentStatus"]["status"] do
      "successful" -> "text-green-800"
      "running" -> "text-blue-800"
      _ -> "text-yellow-800"
    end
  end

  def preview_url(app) do
    "https://#{app["name"]}.fly.dev"
  end

  def format_health_checks(checks) do
    total = Enum.count(checks)

    passing =
      Enum.reduce(checks, 0, fn check, acc ->
        if check["status"] === "passing", do: acc + 1, else: acc
      end)

    "#{passing} / #{total}"
  end

  def human_readable_datetime(datetime),
    do: "#{datetime.hour}:#{datetime.minute}:#{datetime.second}"
end
