defmodule AiAgentAdvisorWeb.ChatLive do
  use AiAgentAdvisorWeb, :live_view

  defstruct [:role, :content]

  @impl true
  def mount(_params, _session, socket) do
    messages = [
      %__MODULE__{
        role: :assistant,
        content: "Hello! I'm your AI Agent. How can I help you today?"
      }
    ]

    socket =
      socket
      |> assign(messages: messages, new_message: "")
      |> assign(page_title: "AI Agent Chat")

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"_target" => ["new_message"], "new_message" => new_message}, socket) do
    {:noreply, assign(socket, new_message: new_message)}
  end

  def handle_event("send_message", %{"new_message" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("send_message", %{"new_message" => new_message}, socket) do
    user_message = %__MODULE__{role: :user, content: new_message}

    # Add the user's message to the list
    messages = socket.assigns.messages ++ [user_message]
    socket = assign(socket, messages: messages, new_message: "")

    parent_pid = self()

    Task.start(fn ->
      Process.sleep(1000)
      ai_response = "This is a placeholder response to your message: '#{new_message}'"
      send(self(), {:ai_response, ai_response})
    end)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:ai_response, content}, socket) do
    ai_message = %__MODULE__{role: :assistant, content: content}
    messages = socket.assigns.messages ++ [ai_message]
    {:noreply, assign(socket, messages: messages)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-screen flex flex-col bg-gray-100 dark:bg-gray-900">
      <%!-- Header --%>
      <header class="flex-shrink-0 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700">
        <div class="mx-auto px-4 sm:px-6 lg:px-8">
          <div class="flex items-center justify-between h-16">
            <h1 class="text-xl font-semibold text-gray-900 dark:text-white">AI Agent Chat</h1>
            <.link href={~p"/settings"} class="text-sm font-medium text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200">
              Settings
            </.link>
          </div>
        </div>
      </header>

      <%!-- Message List --%>
      <div class="flex-1 overflow-y-auto">
        <div class="px-4 py-6 sm:px-6 lg:px-8">
          <div class="space-y-6">
            <%= for message <- @messages do %>
              <div class={"flex items-start gap-4 #{if message.role == :user, do: "justify-end"}"}>
                <%= if message.role == :assistant do %>
                  <span class="flex-shrink-0 w-8 h-8 rounded-full bg-indigo-500 flex items-center justify-center text-white">
                    <.icon name="hero-sparkles" class="w-5 h-5" />
                  </span>
                <% end %>

                <div class={"max-w-lg p-3 rounded-lg #{
                  if message.role == :user,
                    do: "bg-indigo-600 text-white",
                    else: "bg-white dark:bg-gray-700 dark:text-gray-200"
                  }"}>
                  <p class="text-sm"><%= message.content %></p>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <%!-- Message Input Form --%>
      <div class="bg-white dark:bg-gray-800 border-t border-gray-200 dark:border-gray-700 p-4">
        <form phx-submit="send_message" phx-change="validate" class="max-w-3xl mx-auto flex items-center gap-4">
          <input
            type="text"
            name="new_message"
            value={@new_message}
            placeholder="Ask your agent a question..."
            autocomplete="off"
            phx-debounce="200"
            class="flex-1 block w-full rounded-md border-gray-300 dark:border-gray-600 dark:bg-gray-700 dark:text-white shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm px-4 py-2"
          />
          <button
            type="submit"
            class="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 disabled:opacity-50"
            disabled={@new_message == ""}
          >
            <.icon name="hero-paper-airplane" class="w-5 h-5" />
          </button>
        </form>
      </div>
    </div>
    """
  end
end
