defmodule AiAgentAdvisorWeb.MarkdownHelper do
  @doc """
  Renders a Markdown string as safe HTML.
  """
  def to_html(markdown) when is_binary(markdown) do
    markdown
    |> Earmark.as_html!()
    |> Phoenix.HTML.raw()
  end
end
