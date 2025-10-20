defmodule AiAgentAdvisorWeb.ChatLive do
  use AiAgentAdvisorWeb, :live_view

  alias AiAgentAdvisor.Accounts
  alias AiAgentAdvisor.Agent
  import AiAgentAdvisorWeb.MarkdownHelper

  defstruct [:role, :content]

  @impl true
  def mount(_params, session, socket) do
    user = Accounts.get_user(session["user_id"])

    messages = [
      %__MODULE__{
        role: :assistant,
        content: "Hello! I'm your AI Agent. How can I help you today?"
      }
    ]

    socket =
      socket
      |> assign(current_user: user) # Assign the user to the socket
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
    # We pass the *current* list of messages as the history
    history = socket.assigns.messages
    messages = history ++ [user_message]
    socket = assign(socket, messages: messages, new_message: "")

    parent_pid = self()
    user = socket.assigns.current_user

    Task.start(fn ->
      # Pass the history to the agent
      answer = Agent.ask(user, new_message, history)
      send(parent_pid, {:ai_response, answer})
    end)

    {:noreply, socket}
  end

  defp extract_text_from_agent_response({:ok, text}), do: text
  defp extract_text_from_agent_response(text) when is_binary(text), do: text
  defp extract_text_from_agent_response(_), do: "An unexpected error occurred in the agent's response."

  @impl true
  def handle_info({:ai_response, content}, socket) do
    # FIX: Safely extract the string content from the agent's response.
    text_content = extract_text_from_agent_response(content)
    ai_message = %__MODULE__{role: :assistant, content: text_content}
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

                <div class={"max-w-lg p-3 rounded-lg prose dark:prose-invert #{
                  if message.role == :user,
                    do: "bg-indigo-600 text-white",
                    else: "bg-white dark:bg-gray-700"
                  }"}>
                  <%= if message.role == :assistant do %>
                    <%= to_html(message.content) %>
                  <% else %>
                    <p class="text-sm"><%= message.content %></p>
                  <% end %>
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
