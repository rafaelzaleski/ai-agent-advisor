defmodule AiAgentAdvisorWeb.SettingsLive do
  use AiAgentAdvisorWeb, :live_view

  alias AiAgentAdvisor.Accounts

  @impl true
  def mount(_params, session, socket) do
    # Explicitly fetch the user from the session within the LiveView lifecycle.
    # This is more robust than relying on assigns from the conn.
    user_id = session["user_id"]
    user = if user_id, do: Accounts.get_user(user_id)

    socket =
      assign(socket,
        current_user: user,
        page_title: "Account Settings"
      )

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
      <div class="bg-white dark:bg-gray-800 shadow sm:rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <h3 class="text-lg leading-6 font-medium text-gray-900 dark:text-white">
            Connected Accounts
          </h3>
          <div class="mt-2 max-w-xl text-sm text-gray-500 dark:text-gray-400">
            <p>Manage your connected third-party accounts.</p>
          </div>

          <div class="mt-5 border-t border-gray-200 dark:border-gray-700">
            <dl class="divide-y divide-gray-200 dark:divide-gray-700">
              <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  Google Account
                </dt>
                <dd class="mt-1 flex text-sm text-gray-900 dark:text-gray-200 sm:mt-0 sm:col-span-2">
                  <span class="flex-grow"><%= @current_user.email %></span>
                  <span class="ml-4 flex-shrink-0">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Connected
                    </span>
                  </span>
                </dd>
              </div>

              <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4">
                <dt class="text-sm font-medium text-gray-500 dark:text-gray-400">
                  HubSpot Account
                </dt>
                <dd class="mt-1 flex text-sm text-gray-900 dark:text-gray-200 sm:mt-0 sm:col-span-2">
                  <%= if @current_user.hubspot_access_token do %>
                    <span class="flex-grow">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        Connected
                      </span>
                    </span>
                  <% else %>
                    <span class="flex-grow">Not Connected</span>
                    <span class="ml-4 flex-shrink-0">
                      <.link
                        href={~p"/auth/hubspot?scope=crm.objects.contacts.read%20crm.objects.contacts.write%20crm.schemas.contacts.read%20crm.schemas.contacts.write"}
                        class="rounded-md bg-white dark:bg-gray-700 font-medium text-indigo-600 dark:text-indigo-400 hover:text-indigo-500"
                      >
                        Connect
                      </.link>
                    </span>
                  <% end %>
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>

      <div class="mt-8 text-center">
        <.link
          href={~p"/auth/logout"}
          class="text-sm font-semibold text-red-600 dark:text-red-400 hover:text-red-500"
        >
          Log Out
        </.link>
      </div>
    </div>
    """
  end
end
